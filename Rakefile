require 'rubygems'
require 'bundler/setup'

task :all do
  sh "AR='~>3.0.0' bundle update activerecord && bundle exec rake"
  sh "AR='~>3.1.0.rc4' bundle update activerecord && bundle exec rake"
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # no rspec available
end

# rake install -> install gem locally (for tests)
# rake release -> push to github and release to gemcutter
# rake version:bump:patch -> increase version and add a git-tag
begin
  require 'jeweler'
rescue LoadError => e
  $stderr.puts "Jeweler, or one of its dependencies, is not available:"
  $stderr.puts "#{e.class}: #{e.message}"
  $stderr.puts "Install it with: sudo gem install jeweler"
else
  Jeweler::Tasks.new do |gem|
    gem.name = 'standalone_migrations'
    gem.summary = "A thin wrapper to use Rails Migrations in non Rails projects"
    gem.email = "thuss@gabrito.com"
    gem.homepage = "http://github.com/thuss/standalone-migrations"
    gem.authors = ["Todd Huss", "Michael Grosser"]
    gem.license = "MIT"
  end

  Jeweler::GemcutterTasks.new
end

task default: "spec"
