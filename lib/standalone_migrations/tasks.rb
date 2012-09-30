module StandaloneMigrations
  class Tasks
    class << self
      def configure
        config_database_file = Configurator.new.config
        paths = Rails.application.config.paths
        paths.add "config/database", :with => config_database_file
      end

      def load_tasks
        configure

        MinimalRailtieConfig.load_tasks
        load "active_record/railties/databases.rake"
        load "standalone_migrations/tasks/connection.rake"
      end
    end
  end
end
