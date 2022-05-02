require 'active_support/all'
require 'yaml'

module StandaloneMigrationsNew

  class InternalConfigurationsProxy

    attr_reader :configurations
    def initialize(configurations)
      @configurations = configurations
    end

    def on(config_key)
      if @configurations[config_key] && block_given?
        @configurations[config_key] = yield(@configurations[config_key]) || @configurations[config_key]
      end
      @configurations[config_key]
    end

  end

  class Configurator
    def self.load_configurations
      @env_config ||= Rails.application.config.database_configuration
      ActiveRecord::Base.configurations = @env_config
      @env_config
    end

    def self.environments_config
      proxy = InternalConfigurationsProxy.new(load_configurations)
      yield(proxy) if block_given?
    end

    def initialize(options = {})
      default_schema = ENV['SCHEMA'] || ActiveRecord::Tasks::DatabaseTasks.schema_file_type(ActiveRecord::Base.schema_format)
      defaults = {
        :config       => "db/config.yml",
        :migrate_dir  => "db/migrate",
        :root         => Pathname.pwd,
        :seeds        => "db/seeds.rb",
        :schema       => default_schema
      }
      @options = load_from_file(defaults.dup) || defaults.merge(options)

      ENV['SCHEMA'] = schema
      Rails.application.config.root = root
      Rails.application.config.paths["config/database"] = config
      Rails.application.config.paths["db/migrate"] = migrate_dir
      Rails.application.config.paths["db/seeds.rb"] = seeds
    end

    def config
      @options[:config]
    end

    def migrate_dir
      @options[:migrate_dir]
    end

    def root
      @options[:root]
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
      config_for_all[environment.to_s]
    end

    private

    def configuration_file
      if !ENV['DATABASE']
        ".standalone_migrations_new"
      else
        ".#{ENV['DATABASE']}.standalone_migrations_new"
      end
    end

    def load_from_file(defaults)
      return nil unless File.exists? configuration_file
      config = YAML.load( ERB.new(IO.read(configuration_file)).result )
      {
        :config       => config["config"] ? config["config"]["database"] : defaults[:config],
        :migrate_dir  => (config["db"] || {})["migrate"] || defaults[:migrate_dir],
        :root         => config["root"] || defaults[:root],
        :seeds        => (config["db"] || {})["seeds"] || defaults[:seeds],
        :schema       => (config["db"] || {})["schema"] || defaults[:schema]
      }
    end

  end
end
