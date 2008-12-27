APP_BASE = File.dirname(File.expand_path(__FILE__))
 
namespace :db do
  task :ar_init do
    require 'active_record'
    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml')))
    logger = Logger.new $stderr
    logger.level = Logger::INFO
    ActiveRecord::Base.logger = logger
  end
 
  desc "Migrate the database using the scripts in the migrate directory. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate => :ar_init  do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate(APP_BASE + "/migrations/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end
 
  namespace :schema do
    desc "Create schema.rb file that can be portably used against any DB supported by AR"
    task :dump => :ar_init do
      require 'active_record/schema_dumper'
      File.open(ENV['SCHEMA'] || APP_BASE + "/schema.rb", "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
 
    desc "Load a ar_schema.rb file into the database"
    task :load => :ar_init do
      file = ENV['SCHEMA'] || APP_BASE + "/schema.rb"
      load(file)
    end
  end
end
