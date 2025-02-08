require File.expand_path("../../../standalone_migrations", __FILE__)
namespace :standalone do
  task :connection do
    StandaloneMigrations::Configurator.environments_config do |proxy|
      ActiveRecord::Tasks::DatabaseTasks.database_configuration = proxy.configurations
    end
    StandaloneMigrations::Configurator.load_configurations
    ActiveRecord::Base.establish_connection
    StandaloneMigrations.run_on_load_callbacks
  end
end
