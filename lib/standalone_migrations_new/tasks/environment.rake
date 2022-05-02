require File.expand_path("../../../standalone_migrations_new", __FILE__)
task :environment => ["standalone:connection"] do
end
