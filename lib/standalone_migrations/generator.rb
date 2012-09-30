# these generators are backed by rails' generators
require "rails/generators"
module StandaloneMigrations
  class Generator
    def self.migration(name, options="")
      generator_params = [name] + options.split(" ")
      Rails::Generators.invoke "active_record:migration", generator_params,
        destination_root: Rails.root
    end
  end
end
