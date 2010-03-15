Rails migrations in non-Rails (and non Ruby) projects.  
For this code to work you need Ruby, Gems, ActiveRecord, Rake and a suitable database driver installed.

USAGE
=====
Install Ruby, RubyGems then:
    sudo gem install standalone_migrations

Add to `Rakefile` in your projects base directory:
    begin
      require 'standalone_migrations'
      StandaloneMigrations.tasks
    rescue LoadError
      puts 'gem install standalone_migrations to get db:migrate:* tasks!'
    end

Add database configuration to `config/database.yml` in your projects base directory e.g.:
    development:
      adapter: mysql
      encoding: utf8
      reconnect: false
      database: somedatabase_dev
      pool: 5
      username: root
      password:
      socket: /var/run/mysqld/mysqld.sock

    test:
      ...something similar...

To create a new database migration run:

    rake db:new_migration name=FooBarMigration
    edit migrations/20081220234130_foo_bar_migration.rb

and fill in the up and down migrations. To apply your newest migration

    rake db:migrate

To migrate to a specific version (for example to rollback)

    rake db:migrate VERSION=20081220234130

To migrate a specific database (for example your "testing" database)

    rake db:migrate RAILS_ENV=test

CREDIT
======
This work is based on Lincoln Stoll's blog post: http://lstoll.net/2008/04/stand-alone-activerecord-migrations/  
and David Welton's post http://journal.dedasys.com/2007/01/28/using-migrations-outside-of-rails

FURTHER HELP
============
A good source to learn how to use migrations is:  
http://dizzy.co.uk/ruby_on_rails/cheatsheets/rails-migrations
or if you're lazy and want to just execute raw SQL  

    def self.up
      execute "insert into foo values (123,'something');"
    end

    def self.down
      execute "delete from foo where field='something';"
    end