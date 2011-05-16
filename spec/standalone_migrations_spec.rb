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
    m = `cd spec/tmp/db/migrations && ls`.split("\n").detect { |m| m =~ name }
    m ? "db/migrations/#{m}" : m
  end

  def tmp_file(file)
    "spec/tmp/#{file}"
  end

  def run(cmd)
    `cd spec/tmp && #{cmd} 2>&1 && echo SUCCESS`
  end

  def run_with_output(cmd)
    `cd spec/tmp && #{cmd} 2>&1`
  end

  def make_migration(name, options={})
    task_name = options[:task_name] || 'db:new_migration'
    migration = run("rake #{task_name} name=#{name}").match(%r{db/migrations/\d+.*.rb})[0]
    content = read(migration)
    content.sub!(/def self.down.*?\send/m, "def self.down;puts 'DOWN-#{name}';end")
    content.sub!(/def self.up.*?\send/m, "def self.up;puts 'UP-#{name}';end")
    write(migration, content)
    migration.match(/\d{14}/)[0]
  end

  def make_sub_namespaced_migration(namespace, name)
    # specify complete task name here to avoid conditionals in make_migration
    make_migration(name, :task_name => "db:#{namespace}:new_migration")
  end

  def write_rakefile(config=nil)
    write 'Rakefile', <<-TXT
      $LOAD_PATH.unshift '#{File.expand_path('lib')}'
      begin
        require 'tasks/standalone_migrations'
        MigratorTasks.new do |t|
          t.log_level = Logger::INFO
          #{config}
        end
      rescue LoadError => e
        puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: \#{e})"
      end
    TXT
  end

  def write_multiple_migrations
    write_rakefile %{t.migrations = "db/migrations", "db/migrations2"}
    write "db/migrations/20100509095815_create_tests.rb", <<-TXT
class CreateTests < ActiveRecord::Migration
def self.up
  puts "UP-CreateTests"
end

def self.down
  puts "DOWN-CreateTests"
end
end
    TXT
    write "db/migrations2/20100509095816_create_tests2.rb", <<-TXT
class CreateTests2 < ActiveRecord::Migration
def self.up
  puts "UP-CreateTests2"
end

def self.down
  puts "DOWN-CreateTests2"
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

  describe 'db:create and drop' do
    it "should create the database and drop the database that was created" do
      run_with_output("rake db:create").should match /spec\/tmp\)$/
      run_with_output("rake db:drop").should match /spec\/tmp\)$/
    end
  end

  describe 'db:create when nonexistent environment is specified' do
    it "should provide an informative error message" do
      run_with_output("rake db:create DB=nonexistent").should match /nonexistent database is not configured/
    end
  end

  describe 'db:new_migration' do
    context "single migration path" do
      it "fails if i do not add a name" do
        run("rake db:new_migration").should_not =~ /SUCCESS/
      end

      it "generates a new migration with this name and timestamp" do
        run("rake db:new_migration name=test_abc").should =~ %r{Created migration .*spec/tmp/db/migrations/\d+_test_abc\.rb}
        run("ls db/migrations").should =~ /^\d+_test_abc.rb$/
      end
    end

    context "multiple migration paths" do
      before do
        write_rakefile %{t.migrations = "db/migrations", "db/migrations2"}
      end
      it "chooses the first path" do
        run("rake db:new_migration name=test_abc").should =~ %r{Created migration .*db/migrations/\d+_test_abc\.rb}
      end
    end

    context 'sub-namespaced task' do
      before do
        write_rakefile %{t.sub_namespace = "widgets"}
      end
      it "fails if i do not add a name" do
        run("rake db:widgets:new_migration").should_not =~ /SUCCESS/
      end

      it "generates a new migration with this name and timestamp" do
        run("rake db:widgets:new_migration name=test_widget").should =~ %r{Created migration .*spec/tmp/db/migrations/\d+_test_widget\.rb}
        run("ls db/migrations").should =~ /^\d+_test_widget.rb$/
      end

      it 'does not create top level db:new_migration task' do
        run('rake db:new_migration').should =~ /Don't know how to build task 'db:new_migration'/
      end
    end
  end

  describe 'db:version' do
    it "should start with a new database version" do
      run("rake db:version").should =~ /Current version: 0/
    end
  end

  describe 'db:migrate' do
    context "single migration path" do
      it "does nothing when no migrations are present" do
        run("rake db:migrate").should =~ /SUCCESS/
      end

      it "migrates if i add a migration" do
        run("rake db:new_migration name=xxx")
        result = run("rake db:migrate")
        result.should =~ /SUCCESS/
        result.should =~ /Migrating to Xxx \(#{Time.now.year}/
      end
    end

    context "multiple migration paths" do
      before do
        write_multiple_migrations
      end
      it "runs the migrator on each migration path" do
        result = run("rake db:migrate")
        result.should =~ /Migrating to CreateTests \(2010/
        result.should =~ /Migrating to CreateTests2 \(2010/
      end
    end

    context 'sub-namespaced task' do
      before do
        write_rakefile %{t.sub_namespace = "widgets"}
      end
      it 'runs the migrations' do
        run("rake db:widgets:new_migration name=new_widget")
        result = run("rake db:widgets:migrate")
        result.should =~ /SUCCESS/
        result.should =~ /Migrating to NewWidget \(#{Time.now.year}/
      end

      it 'does not create top level db:new_migration task' do
        run('rake db:migrate').should =~ /Don't know how to build task 'db:migrate'/
      end
    end
  end

  describe 'db:migrate:down' do
    context "single migration path" do
      it "migrates down" do
        make_migration('xxx')
        sleep 1
        version = make_migration('yyy')
        run 'rake db:migrate'

        result = run("rake db:migrate:down VERSION=#{version}")
        result.should =~ /SUCCESS/
        result.should_not =~ /DOWN-xxx/
        result.should =~ /DOWN-yyy/
      end

      it "fails without version" do
        make_migration('yyy')
        result = run("rake db:migrate:down")
        result.should_not =~ /SUCCESS/
      end
    end

    context "multiple migration paths" do
      before do
        write_multiple_migrations
      end

      it "runs down on the correct path" do
        run 'rake db:migrate'
        result = run 'rake db:migrate:down VERSION=20100509095815'
        result.should =~ /DOWN-CreateTests/
        result.should_not =~ /DOWN-CreateTests2/
      end

      it "fails if migration number isn't found" do
        run 'rake db:migrate'
        result = run 'rake db:migrate:down VERSION=20100509095820'
        result.should_not =~ /SUCCESS/
        result.should =~ /wasn't found on path/
      end
    end

    context 'sub-namespaced task' do
      before do
        write_rakefile %{t.sub_namespace = "widgets"}
      end
      it 'migrates down' do
        make_sub_namespaced_migration('widgets', 'widget_xxx')
        sleep 1
        version = make_sub_namespaced_migration('widgets', 'widget_yyy')
        run 'rake db:widgets:migrate'

        result = run("rake db:widgets:migrate:down VERSION=#{version}")
        result.should =~ /SUCCESS/
        result.should_not =~ /DOWN-widget_xxx/
        result.should =~ /DOWN-widget_yyy/
      end
    end
  end

  describe 'db:migrate:up' do
    context "single migration path" do
      it "migrates up" do
        make_migration('xxx')
        run 'rake db:migrate'
        sleep 1
        version = make_migration('yyy')
        result = run("rake db:migrate:up VERSION=#{version}")
        result.should =~ /SUCCESS/
        result.should_not =~ /UP-xxx/
        result.should =~ /UP-yyy/
      end

      it "fails without version" do
        make_migration('yyy')
        result = run("rake db:migrate:up")
        result.should_not =~ /SUCCESS/
      end
    end

    context "multiple migration paths" do
      before do
        write_multiple_migrations
      end

      it "runs down on the correct path" do
        result = run 'rake db:migrate:up VERSION=20100509095815'
        result.should =~ /UP-CreateTests/
        result.should_not =~ /UP-CreateTests2/
      end

      it "fails if migration number isn't found" do
        result = run 'rake db:migrate:up VERSION=20100509095820'
        result.should_not =~ /SUCCESS/
        result.should =~ /wasn't found on path/
      end
    end

    context 'sub-namespaced task' do
      before do
        write_rakefile %{t.sub_namespace = "widgets"}
      end
      it 'migrates up' do
        make_sub_namespaced_migration('widgets', 'widget_xxx')
        run 'rake db:widgets:migrate'
        sleep 1
        version = make_sub_namespaced_migration('widgets', 'widget_yyy')
        result = run("rake db:widgets:migrate:up VERSION=#{version}")
        result.should =~ /SUCCESS/
        result.should_not =~ /UP-widget_xxx/
        result.should =~ /UP-widget_yyy/
      end
    end
  end

  describe 'schema:dump' do
    it "dumps the schema" do
      result = run('rake db:schema:dump')
      result.should =~ /SUCCESS/
      read('db/schema.rb').should =~ /ActiveRecord/
    end
  end

  describe 'db:schema:load' do
    it "loads the schema" do
      run('rake db:schema:dump')
      schema = "db/schema.rb"
      write(schema, read(schema)+"\nputs 'LOADEDDD'")
      result = run('rake db:schema:load')
      result.should =~ /SUCCESS/
      result.should =~ /LOADEDDD/
    end
  end

  describe 'db:abort_if_pending_migrations' do
    it "passes when no migrations are pending" do
      run("rake db:abort_if_pending_migrations").should_not =~ /try again/
    end

    it "fails when migrations are pending" do
      make_migration('yyy')
      result = run("rake db:abort_if_pending_migrations")
      result.should =~ /try again/
      result.should =~ /1 pending migration/
    end
  end

  describe 'db:test:load' do
    it 'loads' do
      write("db/schema.rb", "puts 'LOADEDDD'")
      run("rake db:test:load").should =~ /LOADEDDD.*SUCCESS/m
    end

    it "fails without schema" do
      run("rake db:test:load").should =~ /no such file to load/
    end
  end

  describe 'db:test:purge' do
    it "runs" do
      run('rake db:test:purge').should =~ /SUCCESS/
    end
  end
end
