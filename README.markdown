Rails migrations in non-Rails (and non Ruby) projects.

[![Build Status](https://travis-ci.org/thuss/standalone-migrations.svg?branch=master)](https://travis-ci.org/thuss/standalone-migrations)

WHAT'S NEW
==========
In the 6.x release we've added support for Rails 6 migrations thanks to [Marco Adkins](https://github.com/marcoadkins).

In the 5.x release we have moved to using Rails 5 migrations instead of maintaining our own migration related code. Just about anything you can do with Rails 5 migrations you can now do with [Standalone Migrations](https://github.com/thuss/standalone-migrations) too!

CONTRIBUTE
==========
[Standalone Migrations](https://github.com/thuss/standalone-migrations) relies on the contributions of the open-source community! To submit a fix or an enhancement fork the repository, make your changes, add your name to the *Contributors* section in README.markdown, and send us a pull request! If you're active and do good work we'll add you as a collaborator!

USAGE
=====
Install Ruby, RubyGems and a ruby-database driver (e.g. `gem install mysql` or `gem install mysql2`) then:

    $ gem install standalone_migrations

Add to `Rakefile` in your projects base directory:

```ruby
require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks
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

    rake db:new_migration name=foo_bar_migration
    edit db/migrate/20081220234130_foo_bar_migration.rb

#### If you really want to, you can just execute raw SQL:

```ruby
def up
  execute "insert into foo values (123,'something');"
end

def down
  execute "delete from foo where field='something';"
end
```

### To apply your newest migration:

    rake db:migrate

### To migrate to a specific version (for example to rollback)

    rake db:migrate VERSION=20081220234130

### To migrate a specific database (for example your "testing" database)

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

### on_loaded callbacks

If you would like to use an external library such as [foreigner](https://github.com/matthuhiggins/foreigner) with standalone migrations, you can add the following to your `Rakefile`:

```ruby
require 'foreigner'

StandaloneMigrations.on_loaded do
  Foreigner.load
end
```

### Multiple database support

#### Structure

Create a custom configuration file for each database and name them `.database_name.standalone_migrations`. The same conditions apply as described under Custom Configuration, however you are most likely want to specify all options to avoid conflicts and errors.

An example set up would look like this:

```
app/
|-- db/
|   |-- migrate/
|   |   |-- db1/
|   |   |   |-- 001_migration.rb
|   |   |
|   |   |-- db2/
|   |       |-- 001_migration.rb
|   |
|   |-- config_db1.yml
|   |-- config_db2.yml
|   |-- seeds_db1.rb
|   |-- seeds_db2.rb
|   |-- schema_db1.rb
|   |-- schema_db2.rb
|
|-- .db1.standalone_migrations
|-- .db2.standalone_migrations
```
Sample config file:

```yaml
db:
    seeds: db/seeds_db1.rb
    migrate: db/migrate/db1
    schema: db/schema_db1.rb
config:
    database: db/config_db1.yml
```
Of course you can achieve a different layout by simply editing the paths.

##### Running

You can run the Rake tasks on a particular database by passing the `DATABASE` environment variable to it:

    $ rake db:version DATABASE=db1

Combined with the environment selector:

    $ rake db:migrate DATABASE=db2 RAILS_ENV=production

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

#### Exporting Generated SQL

If instead of the database-agnostic `schema.rb` file you'd like to
save the database-specific SQL generated by the migrations, simply
add this to your `Rakefile`.

```ruby
require 'tasks/standalone_migrations'
ActiveRecord::Base.schema_format = :sql
```

You should see a `db/structure.sql` file the next time you run a
migration.

Contributors
============
 - [Todd Huss](http://gabrito.com/)
 - [Michael Grosser](http://pragmatig.wordpress.com)
 - [Ricardo Valeriano](http://ricardovaleriano.com/)
 - [Two Bit Labs](http://twobitlabs.com/)
 - [Windandtides](http://windandtides.com/)
 - [Eric Lindvall](http://bitmonkey.net)
 - [Steve Hodgkiss](http://stevehodgkiss.com/)
 - [Rich Meyers](https://github.com/richmeyers)
 - [Wes Bailey](http://exposinggotchas.blogspot.com/)
 - [Robert J. Berger](http://blog.ibd.com/)
 - [Federico Builes](http://mheroin.com/)
 - [Gazler](http://blog.gazler.com/)
 - [Yuu Yamashita](https://github.com/yyuu)
 - [Koen Punt](http://www.koen.pt/)
 - [Parker Moore](http://www.parkermoore.de/)
 - [Marcell Jusztin](http://www.morcmarc.com)
 - [Eric Hayes](http://ejhay.es)
 - [Yi Wen](https://github.com/ywen)
 - [Jonathan Rochkind](https://github.com/jrochkind)
 - [Michael Mikhailov](https://github.com/yohanson)
 - [Benjamin Dobell](https://github.com/Benjamin-Dobell)
 - [Hassan Mahmoud](https://github.com/HassanTC)
 - [Marco Adkins](https://github.com/marcoadkins)
 - [Mithun James](https://github.com/drtechie)
 - [Sarah Ridge](https://github.com/smridge)
