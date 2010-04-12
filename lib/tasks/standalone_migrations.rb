# Every important options should be overwriteable with MIGRATION_OPTIONS
base = File.expand_path('.')
here = File.expand_path(File.dirname(File.dirname(File.dirname((__FILE__)))))

options = {
  :base => base,
  :vendor => "#{here}/vendor",
  :migrations => "#{base}/db/migrations",
  :config => "#{base}/db/config.yml",
  :schema => "#{base}/db/schema.rb",
  :env => 'DB',
  :default_env => 'development'
}
options = options.merge(MIGRATION_OPTIONS) if defined?(MIGRATION_OPTIONS)

# Add to load_path every "lib/" directory in vendor
Dir["#{options[:vendor]}/**/lib"].each{|p| $LOAD_PATH << p }

namespace :db do
  task :ar_init do
    require 'logger'
    require 'active_record'
    ENV[options[:env]] ||= options[:default_env]

    require 'erb'
    ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(options[:config])).result)
    ActiveRecord::Base.establish_connection(ENV[options[:env]])
    logger = Logger.new $stderr
    logger.level = Logger::INFO
    ActiveRecord::Base.logger = logger
  end

  desc "Migrate the database using the scripts in the migrations directory. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate => :ar_init  do
    require "#{options[:vendor]}/migration_helpers/init"
    ActiveRecord::Migration.verbose = (ENV["VERBOSE"] == "true")
    ActiveRecord::Migrator.migrate(options[:migrations], ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db:schema:dump"].execute
  end

  namespace :migrate do
    [:up, :down].each do |direction|
      desc "Runs the '#{direction}' for a given migration VERSION."
      task direction => :ar_init do
        version = ENV["VERSION"].to_i
        raise "VERSION is required (must be a number)" if version == 0
        ActiveRecord::Migrator.run(direction, options[:migrations], version)
        Rake::Task["db:schema:dump"].execute
      end
    end
  end
  
  desc "Raises an error if there are pending migrations"
  task :abort_if_pending_migrations => :ar_init do
    pending_migrations = ActiveRecord::Migrator.new(:up, options[:migrations]).pending_migrations

    if pending_migrations.any?
      puts "You have #{pending_migrations.size} pending migrations:"
      pending_migrations.each do |pending_migration|
        puts '  %4d %s' % [pending_migration.version, pending_migration.name]
      end
      abort %{Run "rake db:migrate" to update your database then try again.}
    end
  end

  namespace :schema do
    desc "Create schema.rb file that can be portably used against any DB supported by AR"
    task :dump => :ar_init do
      require 'active_record/schema_dumper'
      File.open(ENV['SCHEMA'] || options[:schema], "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    desc "Load a ar_schema.rb file into the database"
    task :load => :ar_init do
      file = ENV['SCHEMA'] || options[:schema]
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

    FileUtils.mkdir_p(options[:migrations]) unless File.exist?(options[:migrations])
    file_name  = "#{options[:migrations]}/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{migration}.rb"

    File.open(file_name, 'w'){|f| f.write file_contents }

    puts "Created migration #{file_name}"
  end
end