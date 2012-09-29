require File.expand_path("../../../standalone_migrations", __FILE__)
task :environment do
  configurator = StandaloneMigrations::Configurator.new
  ActiveRecord::Base.establish_connection configurator.config_for(Rails.env)
end
