module StandaloneMigrations
  class Configurator

    def initialize(options = {})
      defaults = {
        :config       => "db/config.yml",
        :migrate_dir  => "db/migrate",
        :seeds        => "db/seeds.rb",
        :schema       => "db/schema.rb"
      }
      @options = load_from_file || defaults.merge(options)
    end

    def config
      @options[:config]
    end

    def migrate_dir
      @options[:migrate_dir]
    end

    def seeds
      @options[:seeds]
    end

    def schema
      @options[:schema]
    end

    private

    def configuration_file
      ".standalone_migrations"
    end

    def load_from_file
      return nil unless File.exists? configuration_file
      config = YAML.load( IO.read(configuration_file) ) 
      {
        :config       => config["config"]["database"],
        :migrate_dir  => config["db"]["migrate"],
        :seeds        => config["db"]["seeds"],
        :schema       => config["db"]["schema"]
      }
    end

  end
end
