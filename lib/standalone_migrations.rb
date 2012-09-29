require "rubygems"
require "rails"
require "active_record"

lib_path = File.expand_path("../", __FILE__)
$:.unshift lib_path unless $:.include?(lib_path)

APP_PATH = File.expand_path("#{lib_path}/standalone_migrations/minimal_railtie_config",  __FILE__)

require "standalone_migrations/minimal_railtie_config"
require "standalone_migrations/tasks"

if !ENV["RAILS_ENV"]
  ENV["RAILS_ENV"] = Rails.env || ENV["RACK_ENV"] || "development"
end
