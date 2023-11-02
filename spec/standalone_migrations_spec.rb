require 'spec_helper'
describe 'Standalone migrations' do

  def write(file, content)
    raise "cannot write nil" unless file
    folder = File.dirname(file)
    FileUtils.mkdir_p(folder) if folder != ''
    File.open(file, 'w') { |f| f.write content }
  end

  def read(file)
    File.read(file)
  end

  def migration(name)
    m = `cd db/migrate && ls`.split("\n").detect { |m| m =~ /#{name}/ }
    m ? "db/migrate/#{m}" : m
  end

  def schema
    ENV['SCHEMA'] || ActiveRecord::Tasks::DatabaseTasks.schema_file(ActiveRecord::Base.schema_format)
  end

  def run(cmd)
    result = `#{cmd} 2>&1`
    raise result unless $?.success?
    result
  end

  def make_migration(name, options = {})
    task_name = options[:task_name] || 'db:new_migration'
    migration = run("rake #{task_name} name=#{name}").match(%r{db/migrate/\d+.*.rb})[0]
    content = read(migration)
    content.sub!(/def down.*?\send/m, "def down;puts 'DOWN-#{name}';end")
    content.sub!(/def up.*?\send/m, "def up;puts 'UP-#{name}';end")
    write(migration, content)
    migration.match(/\d{14}/)[0]
  end

  def write_rakefile(config = nil)
    write 'Rakefile', <<-TXT
$LOAD_PATH.unshift '#{File.expand_path('../../lib')}'
begin
  require "standalone_migrations"
  StandaloneMigrations::Tasks.load_tasks
rescue LoadError => e
  puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: \#{e})"
end
    TXT
  end

  def write_multiple_migrations
    migration_superclass = if Rails::VERSION::MAJOR >= 5
                             "ActiveRecord::Migration[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
                           else
                             "ActiveRecord::Migration"
                           end

    write_rakefile %{t.migrations = "db/migrations", "db/migrations2"}
    write "db/migrate/20100509095815_create_tests.rb", <<-TXT
class CreateTests < #{migration_superclass}
  def up
    puts "UP-CreateTests"
  end

  def down
    puts "DOWN-CreateTests"
  end
end
    TXT
    write "db/migrate/20100509095816_create_tests2.rb", <<-TXT
class CreateTests2 < #{migration_superclass}
  def up
    puts "UP-CreateTests2"
  end

  def down
    puts "DOWN-CreateTests2"
  end
end
    TXT
  end

  around(:each) do |example|
    FileUtils.mkdir_p('tmp')
    Dir.mktmpdir("spec-", "tmp") do |dir|
      Dir.chdir(dir) do
        example.run
      end
    end
  end

  before do
    StandaloneMigrations::Configurator.instance_variable_set(:@env_config, nil)
    write_rakefile
    write(schema, '')
    write 'db/config.yml', <<-TXT
development:
  adapter: sqlite3
  database: db/development.sql
test:
  adapter: sqlite3
  database: db/test.sql
production:
  adapter: sqlite3
  database: db/production.sql
    TXT
  end

  it "warns of deprecated folder structure" do
    warning = /DEPRECATED.* db\/migrate/
    expect(run("rake db:create")).not_to match(warning)
    write('db/migrations/fooo.rb', 'xxx')
    expect(run("rake db:create --trace")).to match(warning)
  end

  describe 'db:create and drop' do
    it "should create the database and drop the database that was created" do
      run "rake db:create"
      run "rake db:drop"
    end
  end

  describe 'callbacks' do
    it 'runs the callbacks' do
      expect(StandaloneMigrations::Tasks).to receive(:configure).and_call_original

      connection_established = false
      expect(ActiveRecord::Base).to receive(:establish_connection) do
        connection_established = true
      end
      expect(StandaloneMigrations).to receive(:run_on_load_callbacks) do
        expect(connection_established).to be true
      end

      load "Rakefile"
      Rake::Task['standalone:connection'].invoke
    end
  end

  describe 'db:new_migration' do
    it "fails if i do not add a name" do
      expect { run("rake db:new_migration") }.to raise_error(/name=/)
    end

    it "generates a new migration with this name from ENV and timestamp" do
      expect(run("rake db:new_migration name=test_abc_env")).to match(%r{create(.*)db/migrate/\d+_test_abc_env\.rb})
      expect(run("ls db/migrate")).to match(/^\d+_test_abc_env.rb$/)
    end

    it "generates a new migration with this name from args and timestamp" do
      expect(run("rake db:new_migration[test_abc_args]")).to match(%r{create(.*)db/migrate/\d+_test_abc_args\.rb})
      expect(run("ls db/migrate")).to match(/^\d+_test_abc_args.rb$/)
    end

    it "generates a new migration with the name converted to the Rails migration format" do
      expect(run("rake db:new_migration name=MyNiceModel")).to match(%r{create(.*)db/migrate/\d+_my_nice_model\.rb})
      expect(read(migration('my_nice_model'))).to match(/class MyNiceModel/)
      expect(run("ls db/migrate")).to match(/^\d+_my_nice_model.rb$/)
    end

    it "generates a new migration with name and options from ENV" do
      run("rake db:new_migration name=add_name_and_email_to_users options='name:string email:string'")
      expect(read(migration('add_name_and_email_to_users'))).to match(/add_column :users, :name, :string\n\s*add_column :users, :email, :string/)
    end

    it "generates a new migration with name and options from args" do
      run("rake db:new_migration[add_website_and_username_to_users,website:string/username:string]")
      expect(read(migration('add_website_and_username_to_users'))).to match(/add_column :users, :website, :string\n\s*add_column :users, :username, :string/)
    end
  end

  describe 'db:version' do
    it "should start with a new database version" do
      expect(run("rake db:version")).to match(/Current version: 0/)
    end

    it "should display the current version" do
      run("rake db:new_migration name=test_abc")
      run("rake --trace db:migrate")
      expect(run("rake db:version")).to match(/Current version: #{Time.now.year}/)
    end
  end

  describe 'db:migrate' do
    it "does nothing when no migrations are present" do
      expect(run("rake db:migrate")).not_to match(/Migrating/)
    end

    it "migrates if i add a migration" do
      run("rake db:new_migration name=xxx")
      expect(run("rake db:migrate")).to match(/Xxx: Migrating/i)
    end
  end

  describe 'db:migrate:down' do
    it "migrates down" do
      make_migration('xxx')
      sleep 1
      version = make_migration('yyy')
      run 'rake db:migrate'

      result = run("rake db:migrate:down VERSION=#{version}")
      expect(result).not_to match(/Xxx: reverting/)
      expect(result).to match(/Yyy: reverting/)
    end

    it "fails without version" do
      make_migration('yyy')
      # Rails has a bug where it's sending a bad failure exception
      # https://github.com/rails/rails/issues/28905
      expect { run("rake db:migrate:down") }.to raise_error(/VERSION|version/)
    end
  end

  describe 'db:migrate:up' do
    it "migrates up" do
      make_migration('xxx')
      run 'rake db:migrate'
      sleep 1
      version = make_migration('yyy')
      result = run("rake db:migrate:up VERSION=#{version}")
      expect(result).not_to match(/Xxx: migrating/)
      expect(result).to match(/Yyy: migrating/)
    end

    it "fails without version" do
      make_migration('yyy')
      # Rails has a bug where it's sending a bad failure exception
      # https://github.com/rails/rails/issues/28905
      expect { run("rake db:migrate:up") }.to raise_error(/VERSION|version/)
    end
  end

  describe 'db:rollback' do
    it "does nothing when no migrations have been run" do
      expect(run("rake db:version")).to match(/version: 0/)
      expect(run("rake db:rollback")).to eq('')
      expect(run("rake db:version")).to match(/version: 0/)
    end

    it "rolls back the last migration if one has been applied" do
      write_multiple_migrations
      run("rake db:migrate")
      expect(run("rake db:version")).to match(/version: 20100509095816/)
      expect(run("rake db:rollback")).to match(/revert/)
      expect(run("rake db:version")).to match(/version: 20100509095815/)
    end

    it "rolls back multiple migrations if the STEP argument is given" do
      write_multiple_migrations
      run("rake db:migrate")
      expect(run("rake db:version")).to match(/version: 20100509095816/)
      run("rake db:rollback STEP=2") =~ /revert/
      expect(run("rake db:version")).to match(/version: 0/)
    end
  end

  describe 'schema:dump' do
    it "dumps the schema" do
      write(schema, '')
      run('rake db:schema:dump')
      expect(read(schema)).to match(/ActiveRecord/)
    end
  end

  describe 'db:schema:load' do
    it "loads the schema" do
      run('rake db:schema:dump')
      write(schema, read(schema) + "\nputs 'LOADEDDD'")
      result = run('rake db:schema:load')
      expect(result).to match(/LOADEDDD/)
    end

    it "loads all migrations" do
      make_migration('yyy')
      run "rake db:migrate"
      run "rake db:drop"
      run "rake db:create"
      run "rake db:schema:load"
      expect(run("rake db:migrate").strip).to eq('')
    end
  end

  describe 'db:abort_if_pending_migrations' do
    it "passes when no migrations are pending" do
      expect(run("rake db:abort_if_pending_migrations").strip).to eq('')
    end

    it "fails when migrations are pending" do
      make_migration('yyy')
      expect { run("rake db:abort_if_pending_migrations") }.to raise_error(/1 pending migration/)
    end
  end

  describe 'db:test:load' do
    it 'loads' do
      write(schema, "puts 'LOADEDDD'")
      expect(run("rake db:test:load")).to match(/LOADEDDD/)
    end

    it "fails without schema" do
      schema_path = schema
      `rm -rf #{schema_path}` if File.exist?(schema_path)
      expect { run("rake db:test:load") }.to raise_error(/try again/)
    end
  end

  describe 'db:test:purge' do
    it "runs" do
      run('rake db:test:purge')
    end
  end

  describe "db:seed" do
    it "loads" do
      write("db/seeds.rb", "puts 'LOADEDDD'")
      expect(run("rake db:seed")).to match(/LOADEDDD/)
    end

    describe 'with non-default seed file' do
      let(:yaml_hash) do
        {
          "db" => {
            "seeds" => "db/seeds2.rb",
          }
        }
      end

      before do
        write(".standalone_migrations", yaml_hash.to_yaml)
      end

      it "loads" do
        write("db/seeds2.rb", "puts 'LOADEDDD'")
        expect(run("rake db:seed")).to match(/LOADEDDD/)
      end
    end

    it "does nothing without seeds" do
      expect(run("rake db:seed").length).to eq(0)
    end
  end

  describe "db:reset" do
    it "should not error when a seeds file does not exist" do
      make_migration('yyy')
      run('rake db:migrate DB=test')
      expect { run("rake db:reset") }.not_to raise_error
    end
  end

  describe 'db:migrate when environment is specified' do
    it "runs when using the DB environment variable", :travis_error => true do
      make_migration('yyy')
      run('rake db:migrate RAILS_ENV=test')
      expect(run('rake db:version RAILS_ENV=test')).not_to match(/version: 0/)
      expect(run('rake db:version')).to match(/version: 0/)
    end

    it "should error on an invalid database", :travis_error => true do
      expect { run("rake db:create RAILS_ENV=nonexistent") }.to raise_error(/rake aborted/)
    end
  end
end
