require File.expand_path("../../../standalone_migrations", __FILE__)
task :environment => ["standalone:connection"] do
end
