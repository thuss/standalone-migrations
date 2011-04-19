task :default => :spec

begin
  require 'rspec/core/rake_task'
rescue LoadError => e
  $stderr.puts "RSpec 2, or one of its dependencies, is not available:"
  $stderr.puts "#{e.class}: #{e.message}"
  $stderr.puts "Install it with: sudo gem install rspec"
  $stderr.puts "Test-related tasks will not be available."
  $stderr.puts "If you have RSpec 1 installed you can try running the tests with:"
  $stderr.puts "  spec spec"
  $stderr.puts "However, RSpec 1 is not officially supported."
else
  RSpec::Core::RakeTask.new {|t| t.rspec_opts = ['--color']}
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
    gem.files += ["lib/tasks/*"]
    %w[rake activerecord].each{|d| gem.add_dependency d}
  end

  Jeweler::GemcutterTasks.new
end
