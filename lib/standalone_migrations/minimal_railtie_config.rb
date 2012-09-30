module StandaloneMigrations
  class StandaloneMigrations::MinimalRailtieConfig < Rails::Application
    config.generators.options[:rails] = {orm: :active_record}

    config.generators.options[:active_record] = {
      migration: true,
      timestamps: true
    }
  end
end
