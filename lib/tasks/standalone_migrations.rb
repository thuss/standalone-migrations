require 'rake'
require 'rake/tasklib'
require 'logger'

class MigratorTasks < ::Rake::TaskLib
  attr_accessor :name, :base, :vendor, :config, :schema, :env, :default_env, :verbose, :log_level
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
    @default_env = 'development'
    @verbose = true
    @log_level = Logger::ERROR
    yield self if block_given?
    # Add to load_path every "lib/" directory in vendor
    Dir["#{vendor}/**/lib"].each{|p| $LOAD_PATH << p }
    define
  end
  
  def migrations=(*value)
    @migrations = value.flatten
  end
  
  def define
    namespace :db do
      task :ar_init do
        require 'active_record'
        ENV[@env] ||= @default_env

        require 'erb'
        ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(@config)).result)
        ActiveRecord::Base.establish_connection(ENV[@env])
        logger = Logger.new $stderr
        logger.level = @log_level
        ActiveRecord::Base.logger = logger
      end

      desc "Migrate the database using the scripts in the migrations directory. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
      task :migrate => :ar_init  do
        require "#{@vendor}/migration_helpers/init"
        ActiveRecord::Migration.verbose = ENV['VERBOSE'] || @verbose
        @migrations.each do |path|
          ActiveRecord::Migrator.migrate(path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
        end
        Rake::Task["db:schema:dump"].execute
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
            Rake::Task["db:schema:dump"].execute
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
        task :load => ['db:ar_init', 'db:test:purge'] do
          ActiveRecord::Base.establish_connection(:test)
          ActiveRecord::Schema.verbose = false
          Rake::Task["db:schema:load"].invoke
        end

        desc "Empty the test database"
        task :purge => 'db:ar_init' do
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
            drop_script = "#{config["host"]}.#{config["database"]}.DP1".gsub(/\\/,'-')
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
        task :prepare => ['db:abort_if_pending_migrations', 'db:test:load']
      end

      desc "Create a new migration"
      task :new_migration do |t|
        unless migration = ENV['name']
          puts "Error: must provide name of migration to generate."
          puts "For example: rake #{t.name} name=add_field_to_form"
          abort
        end

        class_name = migration.split('_').map{|s| s.capitalize }.join
        file_contents = <<eof
class #{class_name} < ActiveRecord::Migration
  def self.up
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
eof
        migration_path = @migrations.first
        FileUtils.mkdir_p(migration_path) unless File.exist?(migration_path)
        file_name  = "#{migration_path}/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{migration}.rb"

        File.open(file_name, 'w'){|f| f.write file_contents }

        puts "Created migration #{file_name}"
      end
    end
  end
end