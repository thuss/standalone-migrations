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

  desc "Create a new migration"
  task :new_migration do |t|
    unless ENV['name']
      puts "Error: must provide name of migration to generate."
      puts "For example: rake #{t.name} name=add_field_to_form"
      exit 1
    end

    underscore = lambda { |camel_cased_word|
      camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    }

    migration  = underscore.call( ENV['name'] )
    file_name  = "migrations/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{migration}.rb"
    class_name = migration.split('_').map { |s| s.capitalize }.join

    file_contents = <<eof
class #{class_name} < ActiveRecord::Migration
  def self.up
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
eof
    File.open(file_name, 'w') { |f| f.write file_contents }

    puts "Created migration #{file_name}"
  end
end
