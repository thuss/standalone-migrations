require 'active_record'
require_relative './app/models/movie'

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '.', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

ActiveRecord::Base.establish_connection(db_configuration["development"])
