task :default => :spec
require 'spec/rake/spectask'
Spec::Rake::SpecTask.new {|t| t.spec_opts = ['--color']}

# rake install -> install gem locally (for tests)
# rake release -> push to github and release to gemcutter
# rake version:bump:patch -> increase version and add a git-tag
begin
  require 'jeweler'
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
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end
