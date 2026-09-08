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

    # True when .load_configurations can succeed: it is a no-op once the config
    # has been memoized, and Rails only raises for a missing file when
    # DATABASE_URL is set to something usable -- given that, Rails hands back an
    # empty config and resolves the URL itself. An empty DATABASE_URL is not
    # usable: Rails accepts it here and then fails resolving the connection.
    def self.database_config_present?
      !@env_config.nil? ||
        Rails.application.config.paths["config/database"].existent.any? ||
        ENV["DATABASE_URL"].present?
    end

    # Set once a Configurator has been built, which is what points
    # paths["config/database"] at db/config.yml. Before that, .environments_config
    # cannot find the config no matter what, so it can tell a genuinely absent
    # config apart from being called too early.
    def self.configured!
      @configured = true
    end

    def self.configured?
      !!@configured
    end

    def self.environments_config
      # Tolerate a missing config file here so that a block in a Rakefile does
      # not abort every rake task before the file exists -- the config may well
      # be written by one of those tasks. Nothing is memoized in that case, so
      # the file is picked up as soon as it appears. Tasks that actually need a
      # database still fail loudly, via the .load_configurations in
      # standalone:connection. See issue #152.
      config =
        if database_config_present?
          load_configurations
        else
          warn_called_too_early unless configured?
          {}
        end
      proxy = InternalConfigurationsProxy.new(config)
      yield(proxy) if block_given?
    end

    def initialize(options = {})
      options = options.dup
      @schema = options.delete('schema')
      @config_overrides = defaults
      c_os['paths'].merge!(options.delete('paths') || {})
      c_os.merge!(options)

      load_from_file

      ENV['SCHEMA'] ||= @schema if @schema
      rac = Rails.application.config

      rac.root = c_os['root']
      c_os['paths'].each do |path, value|
        rac.paths[path] = value
      end

      self.class.configured!
    end

    def config_for_all
      Configurator.load_configurations.dup
    end

    def config_for(environment)
      config_for_all[environment.to_s]
    end

    def c_os
      config_overrides
    end
    def config_overrides
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

    def schema
      @schema
    end

    def self.warn_called_too_early
      warn "StandaloneMigrations::Configurator.environments_config was called " \
           "before StandaloneMigrations::Tasks.load_tasks, so the database " \
           "config had not been located yet and the block was ignored. Move it " \
           "below your StandaloneMigrations::Tasks.load_tasks call."
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
