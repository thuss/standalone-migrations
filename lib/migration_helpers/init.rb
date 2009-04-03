require 'migration_helper'

ActiveRecord::ConnectionAdapters::AbstractAdapter.
  send :include, MigrationConstraintHelpers
