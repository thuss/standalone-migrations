# these generators are backed by rails' generators
require "rails/generators"
require 'rails/generators/active_record/migration/migration_generator'
module StandaloneMigrations
  class Generator
    def self.migration(name, options="")
      generator_params = [name] + options.split(" ")
      Rails::Generators.invoke "active_record:migration", generator_params,
        :destination_root => Rails.root
    end
  end

  class CacheMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
    source_root File.join(File.dirname(ActiveRecord::Generators::MigrationGenerator.instance_method(:create_migration_file).source_location.first), "templates")

    def create_migration_file
      set_local_assigns!
      validate_file_name!
      migration_template @migration_template, Rails.application.config.paths["db/migrate"]
    end
  end
end
