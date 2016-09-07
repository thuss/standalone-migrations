module StandaloneMigrations
  class Tasks
    class << self
      def configure
        Deprecations.new.call
        configurator = Configurator.new
        paths = Rails.application.config.paths
        paths.add "config/database", :with => configurator.config
        paths.add "db/migrate", :with => configurator.migrate_dir
        paths.add "db/seeds.rb", :with => configurator.seeds
      end

      def load_tasks
        configure
        Configurator.environments_config do |proxy|
          ActiveRecord::Tasks::DatabaseTasks.database_configuration = proxy.configurations
        end
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
