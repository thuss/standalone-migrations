module StandaloneMigrations
  class Tasks
    def self.load_tasks
      MinimalRailtieConfig.load_tasks
      load "active_record/railties/databases.rake"
    end
  end
end
