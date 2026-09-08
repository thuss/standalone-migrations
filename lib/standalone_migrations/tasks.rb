module StandaloneMigrations
  class Tasks
    class << self
      def configure(options = {})
        Deprecations.new.call
        Configurator.new options
      end

      def load_tasks(options = {})
        configure(options)
        # Loading the config here, as well as in standalone:connection, leaves
        # ActiveRecord::Base.configurations populated at Rakefile load time,
        # which custom tasks that connect themselves rely on. .environments_config
        # tolerates a missing config file, so unrelated tasks -- including the
        # one that writes the config -- still run. See issue #152.
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
