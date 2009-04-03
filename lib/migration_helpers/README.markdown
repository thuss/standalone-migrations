
DESCRIPTION
===========

Helpers for migrations of ActiveRecord for dealing with foreign keys and primary keys.

FEATURES
========

 * **foreign keys**
    * foreign_key(table, field, referenced_table, referenced_field, on_cascade)
    * drop_foreign_key(table, field)
 * **primary keys**
    * primary_key(table, field)

Examples
========

Typical use:

    def self.up
      create_table :profiles do |t|
        t.string  :first_name
        t.string  :last_name
        t.string  :email
        t.boolean :is_disabled
      end
      create_table :users do |t|
        t.string  :login
        t.string  :crypted_password
        t.string  :salt
        t.integer :profile_id
      end

      foreign_key :users, :profile_id, :profiles
    end

    def self.down
      drop_foreign_key :users, :profile_id
      drop_table       :users
      drop_table       :profiles
    end


Also, if we don't defined a common :id (exactly it's rails who define it), we should create a primary key:

    def self.up
      create_table :foo, :id => false do |t|
         t.string :foo, :bar
      end

      primary_key :foo, [ :foo, :bar ]
    end

In the parameter where a field is required (like the second parameter in *primary_key*) you can specified and symbol (or string) or an array of symbols (or strings).


REQUIREMENTS
============

 * It's been tested with Mysql adapter and Jdbcmysql adapter

INSTALL
=======

 * script/plugin install git://github.com/blaxter/migration_helpers.git

LICENSE
=======

(The MIT License)

Copyright (c) 2008 Jesús García Sáez <jgarcia@warp.es>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
