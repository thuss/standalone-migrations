require 'active_support/all'
require 'yaml'

module StandaloneMigrations

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
      @options = load_from_file

      ENV['SCHEMA'] ||= schema if schema
      Rails.application.config.root = root
      Rails.application.config.paths["config/database"] = config
      Rails.application.config.paths["db/dir"]          = db_dir
      Rails.application.config.paths["db/migrate"]      = migrate_dir
      Rails.application.config.paths["db/seeds.rb"]     = seeds
    end

    def config
      @options[:config]
    end

    def db_dir
      @options[:db]
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

    def defaults
      {
             config: "db/config.yml",
             db_dir: "db"           ,
        migrate_dir: "db/migrate"   ,
               root: Pathname.pwd   ,
              seeds: "db/seeds.rb"  ,
      }
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
        ".standalone_migrations"
      else
        ".#{ENV['DATABASE']}.standalone_migrations"
      end
    end

    def load_from_file
      return nil unless File.exist? configuration_file
      data = YAML.load( ERB.new(IO.read(configuration_file)).result )

      defaults.merge({
             config: data.dig("config", "database"),
             db_dir: data.dig("db"    , "dir"     ),
        migrate_dir: data.dig("db"    , "migrate" ),
               root: data.dig("root"              ),
              seeds: data.dig("db"    , "seeds"   ),
             schema: data.dig("db"    , "schema"  ),
      }.select { |key, value| value.present? } )
    end

  end
end
