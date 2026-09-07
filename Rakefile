require 'rubygems'
require 'bundler/setup'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # no rspec available
end

# rake install -> install gem locally (for tests)
# rake release -> push to github and release to gemcutter
# rake version:bump:patch -> increase version and add a git-tag
#
# Jeweler lives in the :release bundler group so that CI (and anyone just
# running the specs) does not have to install it. `bundle config set --local
# without release` keeps it out of the bundle; the rescue below handles that.
begin
  require 'jeweler'
rescue LoadError => e
  $stderr.puts "Jeweler, or one of its dependencies, is not available:"
  $stderr.puts "#{e.class}: #{e.message}"
  $stderr.puts "It lives in the :release group; install it with: BUNDLE_WITHOUT= bundle install"
else
  Jeweler::Tasks.new do |gem|
    gem.name = 'standalone_migrations'
    gem.summary = "A thin wrapper to use Rails Migrations in non Rails projects"
    gem.email = "thuss@gabrito.com"
    gem.homepage = "http://github.com/thuss/standalone-migrations"
    gem.authors = ["Todd Huss", "Michael Grosser"]
    gem.license = "MIT"
    gem.required_ruby_version = '>= 3.2.0'
  end

  Jeweler::GemcutterTasks.new
end

task default: "spec"
