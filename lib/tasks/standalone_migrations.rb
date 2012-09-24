require 'active_support/all'
require 'active_record'
require 'pathname'
require 'standalone_migrations/configurator'

# earlier versions used migrations from db/migrations, so warn users about the change
if File.directory?('db/migrations')
  puts "DEPRECATED move your migrations into db/migrate"
end

def standalone_configurator
  @configurator ||= StandaloneMigrations::Configurator.new
end

module Rails
  def self.env
    s = (ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['DB'] || 'development').dup # env is frozen -> dup
    def s.development?; self == 'development';end
    s
  end

  def self.root
    Pathname.new Dir.pwd
  end

  def self.application
    s = "fake_app"

    def s.paths
      {
        "db/migrate"   => [standalone_configurator.migrate_dir],
        "db/seeds.rb"  => [standalone_configurator.seeds],
        "db/schema.rb" => [standalone_configurator.schema]
      } 
    end

    def s.config
      s = "fake_config"
      def s.database_configuration
        standalone_configurator.config_for_all
      end
      s
    end
    
    def s.load_seed
      seed_file = paths["db/seeds.rb"].select{ |f| File.exists?(f) }.first
      load(seed_file) if seed_file
    end

    def s.eager_load!
    end

    s
  end

end

task(:rails_env){}

task(:environment => "db:load_config") do
  ActiveRecord::Base.establish_connection standalone_configurator.config_for Rails.env
end

load 'active_record/railties/databases.rake'

namespace :db do
  task :load_config do
    ActiveRecord::Base.configurations = standalone_configurator.config_for_all
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
  def up
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
eof
    filename = migration.underscore
    create_file file_name(filename), file_contents
    puts "Created migration #{file_name filename}"
  end

  def configurator
    standalone_configurator
  end

  def create_file file, contents
    path = File.dirname(file)
    FileUtils.mkdir_p path unless File.exists? path
    File.open(file, 'w') { |f| f.write contents }
  end

  def file_name migration
    File.join configurator.migrate_dir, "#{Time.now.utc.strftime '%Y%m%d%H%M%S'}_#{migration}.rb"
  end

  def class_name str
    str.parameterize.underscore.camelize
  end
end
