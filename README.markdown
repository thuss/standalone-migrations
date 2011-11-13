Rails migrations in non-Rails (and non Ruby) projects.

WHAT'S NEW
==========
In the 1.0 release we have moved to using Rails 3 migrations instead of maintaining our own migration related code. Just about anything you can do with Rails 3 migrations you can now do with [Standalone Migrations](https://github.com/thuss/standalone-migrations) too! This removed 95% of the code we have to maintain. Big thanks to [Michael Grosser](http://pragmatig.wordpress.com) for undertaking this major rewrite!

CONTRIBUTE
==========
[Standalone Migrations](https://github.com/thuss/standalone-migrations) relies on the contributions of the open-source community! To submit a fix or an enhancement fork the repository, checkout the *develop* branch, make your changes, add your name to the *Contributors* section in README.markdown, and send us a pull request! If you're active and do good work we'll add you as a collaborator!

USAGE
=====
Install Ruby, RubyGems and a ruby-database driver (e.g. `gem install mysql`) then:

    sudo gem install standalone_migrations

Add to `Rakefile` in your projects base directory:

```ruby
begin
  require 'tasks/standalone_migrations'
rescue LoadError => e
  puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: #{e})"
end
```

Add database configuration to `db/config.yml` in your projects base directory e.g.:

    development:
      adapter: sqlite3
      database: db/development.sqlite3
      pool: 5
      timeout: 5000

    production:
      adapter: mysql
      encoding: utf8
      reconnect: false
      database: somedatabase_dev
      pool: 5
      username: root
      password:
      socket: /var/run/mysqld/mysqld.sock

    test: &test
      adapter: sqlite3
      database: db/test.sqlite3
      pool: 5
      timeout: 5000

### To create a new database migration:

    rake db:new_migration name=FooBarMigration
    edit db/migrate/20081220234130_foo_bar_migration.rb

... and fill in the up and down migrations [Cheatsheet](http://dizzy.co.uk/ruby_on_rails/cheatsheets/rails-migrations).

#### If you really want to, you can just execute raw SQL:

```ruby
def self.up
  execute "insert into foo values (123,'something');"
end

def self.down
  execute "delete from foo where field='something';"
end
```

#### Even better, you can use the _generate_ task to create the initial migration ####

The general form is:

    rake db:generate model="model_name" fields="type:column_name0 type:column_name1 ... type:column_namen"

You can have as many fields as you would like.

An example to create a Person table with 3 columns (and it will automatically add the t.timestamps line)

    rake db:generate model="Person" fields="string:first_name string:last_name integer:age"

This will create a migration in db/migrate/

```ruby
class CreatePerson < ActiveRecord::Migration
  def self.up
    create_table :Person do |t|
      t.string :first_name
      t.string :last_name
      t.integer :age
      t.timestamps
    end
  end

  def self.down
    drop_table :Person
  end
end
```

### To apply your newest migration:

    rake db:migrate

### To migrate to a specific version (for example to rollback)

    rake db:migrate VERSION=20081220234130

### To migrate a specific database (for example your "testing" database)

    rake db:migrate DB=test ... or ...
    rake db:migrate RAILS_ENV=test

### To execute a specific up/down of one single migration

    rake db:migrate:up VERSION=20081220234130

### To revert your last migration

    rake db:rollback

### To revert your last 3 migrations

    rake db:rollback STEP=3

### Custom configuration

By default, Standalone Migrations will assume there exists a "db/"
directory in your project. But if for some reason you need a specific
directory structure to work with, you can use a configuration file
named .standalone_migrations in the root of your project containing
the following:

```yaml
db:
    seeds: db/seeds.rb
    migrate: db/migrate
    schema: db/schema.rb
config:
    database: db/config.yml
```

These are the configurable options available. You can omit any of
the keys and Standalone Migrations will assume the default values. 

#### Changing environment config in runtime

If you are using Heroku or have to create or change your connection
configuration based on runtime aspects (maybe environment variables),
you can use the `StandaloneMigrations::Configurator.environments_config`
method. Check the usage example:

```ruby
require 'tasks/standalone_migrations'

StandaloneMigrations::Configurator.environments_config do |env|

  env.on "production" do

    if (ENV['DATABASE_URL'])
      db = URI.parse(ENV['DATABASE_URL'])
      return {
        :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
        :host     => db.host,
        :username => db.user,
        :password => db.password,
        :database => db.path[1..-1],
        :encoding => 'utf8'
      }
    end

    nil
  end

end
```

You have to put this anywhere on your `Rakefile`. If you want to
change some configuration, call the #on method on the object
received as argument in your block passed to ::environments_config
method call. The #on method receives the key to the configuration
that you want to change within the block. The block should return
your new configuration hash or nil if you want the configuration
to stay the same.

Your logic to decide the new configuration need to access some data
in your current configuration? Then you should receive the configuration
in your block, like this:

```ruby
require 'tasks/standalone_migrations'

StandaloneMigrations::Configurator.environments_config do |env|

  env.on "my_custom_config" do |current_custom_config|
    p current_custom_config
    # => the values on your current "my_custom_config" environment
    nil
  end

end
```

Contributors
============
 - [Todd Huss](http://gabrito.com/)
 - [Two Bit Labs](http://twobitlabs.com/)
 - [Michael Grosser](http://pragmatig.wordpress.com)
 - [Eric Lindvall](http://bitmonkey.net)
 - [Steve Hodgkiss](http://stevehodgkiss.com/)
 - [Rich Meyers](https://github.com/richmeyers)
 - [Wes Bailey](http://exposinggotchas.blogspot.com/)
 - [Robert J. Berger](http://blog.ibd.com/)
 - [Federico Builes](http://mheroin.com/)
 - [Ricardo Valeriano](http://ricardovaleriano.com/)

This work is originally based on [Lincoln Stoll's blog post](http://lstoll.net/2008/04/stand-alone-activerecord-migrations/) and [David Welton's post](http://journal.dedasys.com/2007/01/28/using-migrations-outside-of-rails).
