require 'rake'
require 'rake/tasklib'
require 'logger'

class MigratorTasks < ::Rake::TaskLib
  DefaultEnv = 'development'

  attr_accessor :name, :base, :vendor, :config, :schema, :env, :current_env
  attr_accessor :verbose, :log_level, :logger, :sub_namespace
  attr_reader :migrations

  def initialize(name = :migrator)
    @name = name
    base = File.expand_path('.')
    here = File.expand_path(File.dirname(File.dirname(File.dirname((__FILE__)))))
    @base = base
    @vendor = "#{here}/vendor"
    @migrations = ["#{base}/db/migrations"]
    @config = "#{base}/db/config.yml"
    @schema = "#{base}/db/schema.rb"
    @env = 'DB'
    @verbose = true
    @log_level = Logger::ERROR
    yield self if block_given?
    # Add to load_path every "lib/" directory in vendor
    Dir["#{vendor}/**/lib"].each { |p| $LOAD_PATH << p }
    define
  end

  def migrations=(*value)
    @migrations = value.flatten
  end

  def define
    namespace :db do
      if sub_namespace
        namespace sub_namespace do
          define_tasks
        end
      else
        define_tasks
      end
    end
  end

  def define_tasks
    sub_namespace_with_separator = sub_namespace ? "#{sub_namespace}:" : ''

    def ar_init(connect = true)
      require 'active_record'
      self.current_env = ENV[@env] || DefaultEnv

      if @config.is_a?(Hash)
        ActiveRecord::Base.configurations = @config
      else
        require 'erb'
        ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(@config)).result)
      end
      ActiveRecord::Base.establish_connection(current_env) if connect
      if @logger
        logger = @logger
      else
        logger = Logger.new($stderr)
        logger.level = @log_level
      end
      ActiveRecord::Base.logger = logger
    end

    task :ar_init do
      ar_init
    end

    desc "Migrate the database using the scripts in the migrations directory. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
    task :migrate => :ar_init do
      require "#{@vendor}/migration_helpers/init"
      ActiveRecord::Migration.verbose = ENV['VERBOSE'] || @verbose
      @migrations.each do |path|
        ActiveRecord::Migrator.migrate(path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      end
      Rake::Task["db:#{sub_namespace_with_separator}schema:dump"].execute
    end

    desc "Retrieves the current schema version number"
    task :version => :ar_init do
      puts "Current version: #{ActiveRecord::Migrator.current_version}"
    end


    def create_database(config)
      begin
        if config['adapter'] =~ /sqlite/
          if File.exist?(config['database'])
            $stderr.puts "#{config['database']} already exists"
          else
            begin
              # Create the SQLite database
              ActiveRecord::Base.establish_connection(config)
              ActiveRecord::Base.connection
            rescue Exception => e
              $stderr.puts e, *(e.backtrace)
              $stderr.puts "Couldn't create database for #{config.inspect}"
            end
          end
          return # Skip the else clause of begin/rescue
        else
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection
        end
      rescue
        case config['adapter']
          when /mysql/
            @charset = ENV['CHARSET'] || 'utf8'
            @collation = ENV['COLLATION'] || 'utf8_unicode_ci'
            creation_options = {:charset => (config['charset'] || @charset), :collation => (config['collation'] || @collation)}
            error_class = config['adapter'] =~ /mysql2/ ? Mysql2::Error : Mysql::Error
            access_denied_error = 1045
            begin
              ActiveRecord::Base.establish_connection(config.merge('database' => nil))
              ActiveRecord::Base.connection.create_database(config['database'], creation_options)
              ActiveRecord::Base.establish_connection(config)
            rescue error_class => sqlerr
              if sqlerr.errno == access_denied_error
                print "#{sqlerr.error}. \nPlease provide the root password for your mysql installation\n>"
                root_password = $stdin.gets.strip
                grant_statement = "GRANT ALL PRIVILEGES ON #{config['database']}.* " \
            "TO '#{config['username']}'@'localhost' " \
            "IDENTIFIED BY '#{config['password']}' WITH GRANT OPTION;"
                ActiveRecord::Base.establish_connection(config.merge(
                                                            'database' => nil, 'username' => 'root', 'password' => root_password))
                ActiveRecord::Base.connection.create_database(config['database'], creation_options)
                ActiveRecord::Base.connection.execute grant_statement
                ActiveRecord::Base.establish_connection(config)
              else
                $stderr.puts sqlerr.error
                $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{config['charset'] || @charset}, collation: #{config['collation'] || @collation}"
                $stderr.puts "(if you set the charset manually, make sure you have a matching collation)" if config['charset']
              end
            end
          when 'postgresql'
            @encoding = config['encoding'] || ENV['CHARSET'] || 'utf8'
            begin
              ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
              ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
              ActiveRecord::Base.establish_connection(config)
            rescue Exception => e
              $stderr.puts e, *(e.backtrace)
              $stderr.puts "Couldn't create database for #{config.inspect}"
            end
        end
      else
        $stderr.puts "#{config['database']} already exists" unless config['adapter'] =~ /sqlite/
      end
    end

    desc 'Create the database from config/database.yml for the current DATABASE_ENV'
    task :create do
      ar_init(false)
      config = ActiveRecord::Base.configurations[self.current_env]
      create_database config
    end

    def drop_database(config)
      case config['adapter']
        when /mysql/
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection.drop_database config['database']
        when /^sqlite/
          require 'pathname'
          path = Pathname.new(config['database'])
          file = path.absolute? ? path.to_s : File.join(@base, path)
          FileUtils.rm(file)
        when 'postgresql'
          ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
          ActiveRecord::Base.connection.drop_database config['database']
      end
    end

    desc 'Drops the database for the current DATABASE_ENV'
    task :drop => :ar_init do
      config = ActiveRecord::Base.configurations[current_env]
      drop_database(config)
    end

    namespace :migrate do
      [:up, :down].each do |direction|
        desc "Runs the '#{direction}' for a given migration VERSION."
        task direction => :ar_init do
          ActiveRecord::Migration.verbose = @verbose
          version = ENV["VERSION"].to_i
          raise "VERSION is required (must be a number)" if version == 0
          migration_path = nil
          if @migrations.length == 1
            migration_path = @migrations.first
          else
            @migrations.each do |path|
              Dir[File.join(path, '*.rb')].each do |file|
                if File.basename(file).match(/^\d+/)[0] == version.to_s
                  migration_path = path
                  break
                end
              end
            end
            raise "Migration #{version} wasn't found on paths #{@migrations.join(', ')}" if migration_path.nil?
          end
          ActiveRecord::Migrator.run(direction, migration_path, version)
          Rake::Task["db:#{sub_namespace_with_separator}schema:dump"].execute
        end
      end
    end

    desc "Raises an error if there are pending migrations"
    task :abort_if_pending_migrations => :ar_init do
      @migrations.each do |path|
        pending_migrations = ActiveRecord::Migrator.new(:up, path).pending_migrations

        if pending_migrations.any?
          puts "You have #{pending_migrations.size} pending migrations:"
          pending_migrations.each do |pending_migration|
            puts '  %4d %s' % [pending_migration.version, pending_migration.name]
          end
          abort %{Run "rake db:migrate" to update your database then try again.}
        end
      end
    end

    namespace :schema do
      desc "Create schema.rb file that can be portably used against any DB supported by AR"
      task :dump => :ar_init do
        if schema_file = ENV['SCHEMA'] || @schema
          require 'active_record/schema_dumper'
          File.open(schema_file, "w") do |file|
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
      end

      desc "Load a ar_schema.rb file into the database"
      task :load => :ar_init do
        file = ENV['SCHEMA'] || @schema
        load(file)
      end
    end

    namespace :test do
      desc "Recreate the test database from the current schema.rb"
      task :load => ["db:#{sub_namespace_with_separator}ar_init", "db:#{sub_namespace_with_separator}test:purge"] do
        ActiveRecord::Base.establish_connection(:test)
        ActiveRecord::Schema.verbose = false
        Rake::Task["db:#{sub_namespace_with_separator}schema:load"].invoke
      end

      desc "Empty the test database"
      task :purge => "db:#{sub_namespace_with_separator}ar_init" do
        config = ActiveRecord::Base.configurations['test']
        case config["adapter"]
          when "mysql"
            ActiveRecord::Base.establish_connection(:test)
            ActiveRecord::Base.connection.recreate_database(config["database"], config)
          when "postgresql" #TODO i doubt this will work <-> methods are not defined
            ActiveRecord::Base.clear_active_connections!
            drop_database(config)
            create_database(config)
          when "sqlite", "sqlite3"
            db_file = config["database"] || config["dbfile"]
            File.delete(db_file) if File.exist?(db_file)
          when "sqlserver"
            drop_script = "#{config["host"]}.#{config["database"]}.DP1".gsub(/\\/, '-')
            `osql -E -S #{config["host"]} -d #{config["database"]} -i db\\#{drop_script}`
            `osql -E -S #{config["host"]} -d #{config["database"]} -i db\\test_structure.sql`
          when "oci", "oracle"
            ActiveRecord::Base.establish_connection(:test)
            ActiveRecord::Base.connection.structure_drop.split(";\n\n").each do |ddl|
              ActiveRecord::Base.connection.execute(ddl)
            end
          when "firebird"
            ActiveRecord::Base.establish_connection(:test)
            ActiveRecord::Base.connection.recreate_database!
          else
            raise "Task not supported by #{config["adapter"].inspect}"
        end
      end

      desc 'Check for pending migrations and load the test schema'
      task :prepare => ["db:#{sub_namespace_with_separator}abort_if_pending_migrations", "db:#{sub_namespace_with_separator}test:load"]
    end

    desc 'generate a model=name field="field1:type field2:type"'
    task :generate do
      ts = Time.now.strftime '%Y%m%d%H%%M%S'

      if ENV['model']
        table_name = ENV['model']
      else
        print 'model name> '
        table_name = $stdin.gets.strip
      end

      raise ArgumentError, 'must provide a name for the model to generate' if table_name.empty?

      create_table_str = "create_table :#{table_name} do |t|"

      fields = ENV['fields'] if ENV['fields']

      columns = ENV.has_key?('fields') ? ENV['fields'].split.map { |v| "t.#{v.sub(/:/, ' :')}" }.join("\n#{' '*6}") : nil

      create_table_str << "\n      #{columns}" if columns

      contents = <<-MIGRATION
class Create#{class_name table_name} < ActiveRecord::Migration
  def self.up
    #{create_table_str}   
      t.timestamps
    end
  end
           
  def self.down
    drop_table :#{table_name}
  end
end
        MIGRATION

      create_file @migrations.first, file_name("create_#{table_name}"), contents
    end

    desc "Create a new migration"
    task :new_migration do |t|
      unless migration = ENV['name']
        puts "Error: must provide name of migration to generate."
        puts "For example: rake #{t.name} name=add_field_to_form"
        abort
      end

      file_contents = <<eof
class #{class_name migration} < ActiveRecord::Migration
  def self.up
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
eof

      create_file @migrations.first, file_name(migration), file_contents

      puts "Created migration #{file_name migration}"
    end
  end

  def class_name str
    str.split('_').map { |s| s.capitalize }.join
  end

  def create_file path, file, contents
    FileUtils.mkdir_p path unless File.exists? path
    File.open(file, 'w') { |f| f.write contents }
  end

  def file_name migration
    File.join @migrations.first, "#{Time.now.utc.strftime '%Y%m%d%H%M%S'}_#{migration}.rb"
  end
end
