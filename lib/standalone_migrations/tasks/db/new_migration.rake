namespace :db do
  desc "Creates a new migration file with the specified name"
  task :new_migration, :name, :options do |t, args|
    name = args[:name] || ENV['name']
    options = args[:options] || ENV['options']
    
    unless name
      puts "Error: must provide name of migration to generate."
      puts "For example: rake #{t.name} name=add_field_to_form"
      abort
    end
    
    if options
      StandaloneMigrations::Generator.migration name, options.gsub('/', ' ')
    else
      StandaloneMigrations::Generator.migration name
    end
  end
end
