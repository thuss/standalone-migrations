module StandaloneMigrations
  class Tasks
    class << self
      def configure
        Deprecations.new.call
        config_database_file = Configurator.new.config
        paths = Rails.application.config.paths
        paths.add "config/database", :with => config_database_file
      end

      def load_tasks
        configure

        MinimalRailtieConfig.load_tasks
        %w(
          connection
          environment
          db/new_migration
        ).each do
          |task| load "standalone_migrations/tasks/#{task}.rake"
        end
        load "active_record/railties/databases.rake"
      end
    end
  end

  class Tasks::Deprecations
    def call
      if File.directory?('db/migrations')
        puts "DEPRECATED move your migrations into db/migrate"
      end
    end
  end
end
