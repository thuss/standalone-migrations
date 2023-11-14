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
      load_from_file

      ENV['SCHEMA'] ||= @schema if @schema
      rac = Rails.application.config

      rac.root = @config_overrides[:root]
      @config_overrides[:paths].each do |path, value|
        rac.paths[path] = value
      end
    end

    def defaults
      {
        paths: {
          "config/database" => "db/config.yml",
                       "db" => "db"           ,
               "db/migrate" => "db/migrate"   ,
              "db/seeds.rb" => "db/seeds.rb"  ,
        },
        root: Pathname.pwd,
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
      ".#{ENV['DATABASE']}.standalone_migrations".sub(/^\.\./, '.')
    end

    def load_from_file
      return nil unless File.exist? configuration_file
      data = YAML.load( ERB.new(IO.read(configuration_file)).result )

      @schema = data.dig("db", "schema")
      @config_overrides = defaults.merge({
        paths: {
          "config/database" => data.dig("config", "database"),
                       "db" => data.dig("db"    , "dir"     ),
               "db/migrate" => data.dig("db"    , "migrate" ),
              "db/seeds.rb" => data.dig("db"    , "seeds"   ),
        }.select { |key, value| value.present? },
          root: data.dig("root"),
      }.select { |key, value| value.present? })
    end
  end
end
