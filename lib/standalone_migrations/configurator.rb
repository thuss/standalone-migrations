module StandaloneMigrations
  class Configurator

    def initialize(options = {})
      defaults = {
        :config       => "config/database.yml",
        :migrate_dir  => "db/migrate",
        :seeds        => "db/seeds.rb",
        :schema       => "db/schema.rb"
      }
    end

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
