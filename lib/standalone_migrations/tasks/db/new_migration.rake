namespace :db do
  task :new_migration do |t|
    unless name = ENV['name']
      puts "Error: must provide name of migration to generate."
      puts "For example: rake #{t.name} name=add_field_to_form"
      abort
    end
    StandaloneMigrations::Generator.migration name
  end
end
