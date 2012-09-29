lib_path = File.expand_path("../", __FILE__)
$:.unshift lib_path unless $:.include?(lib_path)

require "rubygems"
require "rails"
require "active_record"

require "standalone_migrations/configurator"

railtie_app_path = "#{lib_path}/standalone_migrations/minimal_railtie_config"
APP_PATH = File.expand_path(railtie_app_path,  __FILE__)

require "standalone_migrations/minimal_railtie_config"
require "standalone_migrations/tasks"

if !ENV["RAILS_ENV"]
  ENV["RAILS_ENV"] = ENV["DB"] || ENV["RACK_ENV"] || Rails.env || "development"
end
