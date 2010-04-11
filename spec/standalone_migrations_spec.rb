describe 'Standalone migrations' do
  def write(file, content)
    raise "cannot write nil" unless file
    file = tmp_file(file)
    folder = File.dirname(file)
    `mkdir -p #{folder}` unless File.exist?(folder)
    File.open(file,'w'){|f| f.write content}
  end

  def read(file)
    File.read(tmp_file(file))
  end

  def migration(name)
    m = `cd spec/tmp/db/migrations && ls`.split("\n").detect{|m| m =~ name}
    m ? "db/migrations/#{m}" : m
  end

  def tmp_file(file)
    "spec/tmp/#{file}"
  end

  def run(cmd)
    `cd spec/tmp && #{cmd} 2>&1`
  end

  before do
    `rm -rf spec/tmp` if File.exist?('spec/tmp')
    `mkdir spec/tmp`
    write 'Rakefile', <<-TXT
      $LOAD_PATH.unshift '#{File.expand_path('lib')}'
      begin
        require 'tasks/standalone_migrations'
      rescue LoadError => e
        puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: \#{e})"
      end
    TXT
    write 'db/config.yml', <<-TXT
      development:
        adapter: sqlite3
        database: db/development.sql
    TXT
  end

  describe 'db:new_migration' do
    it "fails if i do not add a name" do
      run("rake db:new_migration").should =~ /Error/
    end

    it "generates a new migration with this name and timestamp" do
      run("rake db:new_migration name=test_abc").should =~ %r{Created migration .*spec/tmp/db/migrations/\d+_test_abc\.rb}
      run("ls db/migrations").should =~ /^\d+_test_abc.rb$/
    end
  end

  describe 'db:migrate' do
    it "does nothing when no migrations are present" do
      run("rake db:migrate").should_not =~ /rake aborted/
    end

    it "migrates if i add a migration" do
      run("rake db:new_migration name=xxx")
      result = run("rake db:migrate")
      result.should_not =~ /rake aborted/
      result.should =~ /Migrating to Xxx \(#{Time.now.year}/
    end
  end

  describe 'db:migrate:down' do
    it "migrates down" do
      run "rake db:new_migration name=xxx"
      sleep 1
      version = run("rake db:new_migration name=yyy").match(/\d+/)[0]
      run "rake db:migrate"

      [/xxx/,/yyy/].each_with_index do |mig, i|
        migration = migration(mig)
        write(migration, read(migration).sub(/def self.down.*?\send/m, "def self.down;puts 'STEP #{i}';end"))
      end

      result = run("rake db:migrate:down VERSION=#{version}")
      result.should_not =~ /rake aborted/
      result.should_not =~ /STEP 0/
      result.should =~ /STEP 1/
    end
  end
end