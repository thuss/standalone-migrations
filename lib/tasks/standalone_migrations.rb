require 'active_support/all'
require 'active_record'
require 'pathname'

DB_CONFIG = YAML.load_file('db/config.yml').with_indifferent_access

module Rails
  def self.env
    s = ENV['RAILS_ENV'] || 'development'
    def s.development?; self == 'development';end
    s
  end

  def self.root
    Pathname.new Dir.pwd
  end

  def self.application
    s = "fake_app"

    def s.paths
      Dir.glob('db/*').inject({}){|hash,x|hash[x]=x; hash}
    end

    def s.config
      s = "fake_config"
      def s.database_configuration
        DB_CONFIG
      end
      s
    end
    s
  end
end

task(:rails_env){}

task(:environment) do
  ActiveRecord::Base.establish_connection DB_CONFIG[Rails.env]
end

load 'active_record/railties/databases.rake'

namespace :db do
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
    create_file file_name(migration), file_contents
    puts "Created migration #{file_name migration}"
  end
end

def create_file file, contents
  path = File.dirname(file)
  FileUtils.mkdir_p path unless File.exists? path
  File.open(file, 'w') { |f| f.write contents }
end

def file_name migration
  File.join 'db/migrate', "#{Time.now.utc.strftime '%Y%m%d%H%M%S'}_#{migration}.rb"
end

def class_name str
  str.split('_').map { |s| s.capitalize }.join
end
