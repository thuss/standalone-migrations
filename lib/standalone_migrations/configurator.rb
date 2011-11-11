module StandaloneMigrations
  class Configurator

    def initialize(options = {})
      defaults = {
        :config       => "db/config.yml",
        :migrate_dir  => "db/migrate",
        :seeds        => "db/seeds.rb",
        :schema       => "db/schema.rb"
      }
      @options = load_from_file(defaults.dup) || defaults.merge(options)
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

    def load_from_file(defaults)
      return nil unless File.exists? configuration_file
      config = YAML.load( IO.read(configuration_file) ) 
      {
        :config       => config["config"] ? config["config"]["database"] : defaults[:config],
        :migrate_dir  => config["db"] ? config["db"]["migrate"] : defaults[:migrate_dir],
        :seeds        => config["db"] ? config["db"]["seeds"] : defaults[:seeds],
        :schema       => config["db"] ? config["db"]["schema"] : defaults[:schema]
      }
    end

  end
end
