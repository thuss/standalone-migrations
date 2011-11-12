require 'active_support/all'

module StandaloneMigrations
  class Configurator
    def self.load_configurations
      @standalone_configs ||= Configurator.new.config
      @environments_config ||= YAML.load(ERB.new(File.read(@standalone_configs)).result).with_indifferent_access
    end

    def self.environments_config
      yield(load_configurations) if block_given?
    end

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

    def config_for_all
      Configurator.load_configurations.dup
    end

    def config_for(environment)
      config_for_all[environment]
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
