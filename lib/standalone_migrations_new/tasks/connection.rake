require File.expand_path("../../../standalone_migrations_new", __FILE__)
namespace :standalone do
  task :connection do
    StandaloneMigrationsNew::Configurator.load_configurations
    ActiveRecord::Base.establish_connection
    StandaloneMigrationsNew.run_on_load_callbacks
  end
end
