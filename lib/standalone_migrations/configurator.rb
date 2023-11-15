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

      rac.root = c_os['root']
      c_os['paths'].each do |path, value|
        rac.paths[path] = value
      end
    end

    def config_for_all
      Configurator.load_configurations.dup
    end

    def config_for(environment)
      config_for_all[environment.to_s]
    end

    def c_os
      @config_overrides
    end

    def c_o_p_m
      config_override_path_mappings
    end
    def config_override_path_mappings
      {
        'config/database' => {
          'config_key_path' => ['config', 'database'],
                  'default' => 'db/config.yml'
        },
                     'db' => {
          'config_key_path' => ['db'    , 'dir'     ],
                  'default' => 'db'
        },
             'db/migrate' => {
          'config_key_path' => ['db'    , 'migrate' ],
                  'default' => 'db/migrate'
        },
            'db/seeds.rb' => {
          'config_key_path' => ['db'    , 'seeds'   ],
                  'default' => 'db/seeds.rb'
        },
      }
    end

    def defaults
      {
        'paths' => c_o_p_m.map do |path, value|
          [ path, value['default'] ]
        end.to_h,
        'root' => Pathname.pwd,
      }
    end

    private

    def configuration_file
      ".#{ENV['DATABASE']}.standalone_migrations".sub(/^\.\./, '.')
    end

    def load_from_file
      return nil unless File.exist? configuration_file
      data = YAML.load( ERB.new(IO.read(configuration_file)).result )

      @schema = data.dig('db', 'schema')

      c_o_paths = c_o_p_m.map do |path, value|
        [
          path,
          data.dig(*value['config_key_path'])
        ]
      end.to_h.select { |key, value| value.present? }

      c_o_paths = defaults['paths'].merge(c_o_paths)

      @config_overrides = defaults.merge({
        'paths' => c_o_paths,
        'root'  => data.dig('root'),
      }.select { |key, value| value.present? })
    end
  end
end
