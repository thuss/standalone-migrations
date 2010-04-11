# Every important should be overwriteable with MIGRATION_OPTIONS
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
    config = YAML.load_file(options[:config])[ENV[options[:env]]]
    ActiveRecord::Base.establish_connection(config)
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
