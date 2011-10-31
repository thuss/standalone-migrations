module StandaloneMigrations
  class Configurator

    def config
      "config/database.yml"
    end

    def migrate_dir
      "db/migrate"
    end

    def seeds
      "db/seeds.rb"
    end

    def schema
      "db/schema.rb"
    end

  end
end
