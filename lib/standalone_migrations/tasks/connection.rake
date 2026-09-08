require File.expand_path("../../../standalone_migrations", __FILE__)
namespace :standalone do
  task :connection do
    StandaloneMigrations::Configurator.environments_config do |proxy|
      ActiveRecord::Tasks::DatabaseTasks.database_configuration = proxy.configurations
    end
    # Unlike .environments_config above, this raises when the config is still
    # missing: a task that needs a database should fail here with a clear
    # message rather than later with a confusing one.
    StandaloneMigrations::Configurator.load_configurations
    ActiveRecord::Base.establish_connection
    StandaloneMigrations.run_on_load_callbacks
  end
end
