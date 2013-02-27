describe 'Standalone migrations' do

  def write(file, content)
    raise "cannot write nil" unless file
    file = tmp_file(file)
    folder = File.dirname(file)
    `mkdir -p #{folder}` unless File.exist?(folder)
    File.open(file, 'w') { |f| f.write content }
  end

  def read(file)
    File.read(tmp_file(file))
  end

  def migration(name)
    m = `cd spec/tmp/db/migrate && ls`.split("\n").detect { |m| m =~ /#{name}/ }
    m ? "db/migrate/#{m}" : m
  end

  def tmp_file(file)
    "spec/tmp/#{file}"
  end

  def run(cmd)
    result = `cd spec/tmp && #{cmd} 2>&1`
    raise result unless $?.success?
    result
  end

  def make_migration(name, options={})
    task_name = options[:task_name] || 'db:new_migration'
    migration = run("rake #{task_name} name=#{name}").match(%r{db/migrate/\d+.*.rb})[0]
    content = read(migration)
    content.sub!(/def change.*?\send/m, "def change; reversible {|dir| dir.up{ puts 'UP-#{name}' }; dir.down{ puts 'DOWN-#{name}'}}; end")
    write(migration, content)
    migration.match(/\d{14}/)[0]
  end

  def write_rakefile(config=nil)
    write 'Rakefile', <<-TXT
$LOAD_PATH.unshift '#{File.expand_path('lib')}'
begin
  require "standalone_migrations"
  StandaloneMigrations::Tasks.load_tasks
rescue LoadError => e
  puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: \#{e})"
end
    TXT
  end

  def write_multiple_migrations
    write_rakefile %{t.migrations = "db/migrations", "db/migrations2"}
    write "db/migrate/20100509095815_create_tests.rb", <<-TXT
class CreateTests < ActiveRecord::Migration
  def change
    reversible { |dir|
      dir.up {
        puts "UP-CreateTests"
      }
      dir.down{
        puts "DOWN-CreateTests"
      }
    }
  end
end
    TXT
    write "db/migrate/20100509095816_create_tests2.rb", <<-TXT
class CreateTests2 < ActiveRecord::Migration
  def change
    reversible { |dir|
      dir.up {
        puts "UP-CreateTests2"
      }
      dir.down{
        puts "DOWN-CreateTests2"
      }
    }
  end
end
    TXT
  end

  before do
    `rm -rf spec/tmp` if File.exist?('spec/tmp')
    `mkdir spec/tmp`
    write_rakefile
    write 'db/config.yml', <<-TXT
development:
  adapter: sqlite3
  database: db/development.sql
test:
  adapter: sqlite3
  database: db/test.sql
    TXT
  end

  after(:all) do
    `rm -rf spec/tmp` if File.exist?('spec/tmp')
  end

  it "warns of deprecated folder structure" do
    warning = /DEPRECATED.* db\/migrate/
    run("rake db:create").should_not =~ warning
    write('db/migrations/fooo.rb', 'xxx')
    run("rake db:create").should =~ warning
  end

  describe 'db:create and drop' do
    it "should create the database and drop the database that was created" do
      run "rake db:create"
      run "rake db:drop"
    end
  end

  describe 'db:new_migration' do
    it "fails if i do not add a name" do
      lambda{ run("rake db:new_migration") }.should raise_error(/name=/)
    end

    it "generates a new migration with this name from ENV and timestamp" do
      run("rake db:new_migration name=test_abc_env").should =~ %r{create(.*)db/migrate/\d+_test_abc_env\.rb}
      run("ls db/migrate").should =~ /^\d+_test_abc_env.rb$/
    end
    
    it "generates a new migration with this name from args and timestamp" do
      run("rake db:new_migration[test_abc_args]").should =~ %r{create(.*)db/migrate/\d+_test_abc_args\.rb}
      run("ls db/migrate").should =~ /^\d+_test_abc_args.rb$/
    end

    it "generates a new migration with the name converted to the Rails migration format" do
      run("rake db:new_migration name=MyNiceModel").should =~ %r{create(.*)db/migrate/\d+_my_nice_model\.rb}
      read(migration('my_nice_model')).should =~ /class MyNiceModel/
      run("ls db/migrate").should =~ /^\d+_my_nice_model.rb$/
    end

    it "generates a new migration with name and options from ENV" do
      run("rake db:new_migration name=add_name_and_email_to_users options='name:string email:string'")
      read(migration('add_name_and_email_to_users')).should =~ /add_column :users, :name, :string\n\s*add_column :users, :email, :string/
    end

    it "generates a new migration with name and options from args" do
      run("rake db:new_migration[add_website_and_username_to_users,website:string/username:string]")
      read(migration('add_website_and_username_to_users')).should =~ /add_column :users, :website, :string\n\s*add_column :users, :username, :string/
    end
  end

  describe 'db:version' do
    it "should start with a new database version" do
      run("rake db:version").should =~ /Current version: 0/
    end

    it "should display the current version" do
      run("rake db:new_migration name=test_abc")
      run("rake --trace db:migrate")
      run("rake db:version").should =~ /Current version: #{Time.now.year}/
    end
  end

  describe 'db:migrate' do
    it "does nothing when no migrations are present" do
      run("rake db:migrate").should_not =~ /Migrating/
    end

    it "migrates if i add a migration" do
      run("rake db:new_migration name=xxx")
      run("rake db:migrate").should =~ /Xxx: Migrating/i
    end
  end

  describe 'db:migrate:down' do
    it "migrates down" do
      make_migration('xxx')
      sleep 1
      version = make_migration('yyy')
      run 'rake db:migrate'

      result = run("rake db:migrate:down VERSION=#{version}")
      result.should_not =~ /DOWN-xxx/
      result.should =~ /DOWN-yyy/
    end

    it "fails without version" do
      make_migration('yyy')
      lambda{ run("rake db:migrate:down") }.should raise_error(/VERSION/)
    end
  end

  describe 'db:migrate:up' do
    it "migrates up" do
      make_migration('xxx')
      run 'rake db:migrate'
      sleep 1
      version = make_migration('yyy')
      result = run("rake db:migrate:up VERSION=#{version}")
      result.should_not =~ /UP-xxx/
      result.should =~ /UP-yyy/
    end

    it "fails without version" do
      make_migration('yyy')
      lambda{ run("rake db:migrate:up") }.should raise_error(/VERSION/)
    end
  end

  describe 'db:rollback' do
    it "does nothing when no migrations have been run" do
      run("rake db:version").should =~ /version: 0/
      run("rake db:rollback").should == ''
      run("rake db:version").should =~ /version: 0/
    end

    it "rolls back the last migration if one has been applied" do
      write_multiple_migrations
      run("rake db:migrate")
      run("rake db:version").should =~ /version: 20100509095816/
      run("rake db:rollback").should =~ /revert/
      run("rake db:version").should =~ /version: 20100509095815/
    end

    it "rolls back multiple migrations if the STEP argument is given" do
      write_multiple_migrations
      run("rake db:migrate")
      run("rake db:version").should =~ /version: 20100509095816/
      run("rake db:rollback STEP=2") =~ /revert/
      run("rake db:version").should =~ /version: 0/
    end
  end

  describe 'schema:dump' do
    it "dumps the schema" do
      write('db/schema.rb', '')
      run('rake db:schema:dump')
      read('db/schema.rb').should =~ /ActiveRecord/
    end
  end

  describe 'db:schema:load' do
    it "loads the schema" do
      run('rake db:schema:dump')
      schema = "db/schema.rb"
      write(schema, read(schema)+"\nputs 'LOADEDDD'")
      result = run('rake db:schema:load')
      result.should =~ /LOADEDDD/
    end

    it "loads all migrations" do
      make_migration('yyy')
      run "rake db:migrate"
      run "rake db:drop"
      run "rake db:create"
      run "rake db:schema:load"
      run( "rake db:migrate").strip.should == ''
    end
  end

  describe 'db:abort_if_pending_migrations' do
    it "passes when no migrations are pending" do
      run("rake db:abort_if_pending_migrations").strip.should == ''
    end

    it "fails when migrations are pending" do
      make_migration('yyy')
      lambda{ run("rake db:abort_if_pending_migrations") }.should raise_error(/1 pending migration/)
    end
  end

  describe 'db:test:load' do
    it 'loads' do
      write("db/schema.rb", "puts 'LOADEDDD'")
      run("rake db:test:load").should =~ /LOADEDDD/
    end

    it "fails without schema" do
      lambda{ run("rake db:test:load") }.should raise_error(/try again/)
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
      run("rake db:seed").should =~ /LOADEDDD/
    end

    it "does nothing without seeds" do
      run("rake db:seed").length.should == 0
    end
  end

  describe "db:reset" do
    it "should not error when a seeds file does not exist" do
      make_migration('yyy')
      run('rake db:migrate DB=test')
      run("rake db:reset").should_not raise_error(/rake aborted/)
    end
  end

  describe 'db:migrate when environment is specified' do
    it "runs when using the DB environment variable" do
      make_migration('yyy')
      run('rake db:migrate DB=test')
      run('rake db:version DB=test').should_not =~ /version: 0/
      run('rake db:version').should =~ /version: 0/
    end

    it "should error on an invalid database" do
      lambda{ run("rake db:create DB=nonexistent")}.should raise_error(/rake aborted/)
    end
  end
end
