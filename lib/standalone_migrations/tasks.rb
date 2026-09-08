module StandaloneMigrations
  class Tasks
    class << self
      def configure(options = {})
        Deprecations.new.call
        Configurator.new options
      end

      def load_tasks(options = {})
        configure(options)
        # Loading the config here (rather than only in standalone:connection)
        # leaves ActiveRecord::Base.configurations populated at Rakefile load
        # time, which custom tasks that connect themselves rely on. Skip it when
        # there is no config file so that unrelated tasks -- including the one
        # that writes the config -- can still run. See issue #152.
        if Rails.application.config.paths["config/database"].existent.any?
          Configurator.environments_config do |proxy|
            ActiveRecord::Tasks::DatabaseTasks.database_configuration = proxy.configurations
          end
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
