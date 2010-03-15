class StandaloneMigrations
  def self.tasks
    load "#{File.dirname(__FILE__)}/../tasks/standalone_migrations.rake"
  end
end