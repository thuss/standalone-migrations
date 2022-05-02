module StandaloneMigrationsNew
  class Tasks
    class << self
      def configure(options = {})
        Deprecations.new.call
        Configurator.new options
      end

      def load_tasks(options = {})
        configure(options)
        Configurator.environments_config do |proxy|
          ActiveRecord::Tasks::DatabaseTasks.database_configuration = proxy.configurations
        end
        MinimalRailtieConfig.load_tasks
        %w(
          connection
          environment
          db/new_migration
        ).each do
          |task| load "standalone_migrations_new/tasks/#{task}.rake"
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
