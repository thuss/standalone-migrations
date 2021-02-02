This is an example minimal app based off of this blog post:

https://www.techcareerbooster.com/blog/use-activerecord-in-your-ruby-project

It demonstrates:

* database configuration
* a migration
* a model
* loading all relevant code into a runtime and using it


```
bundle
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec irb -r ./boot.rb
```

```ruby
Movie.create! title: "Attack of the Cats", director: "Furball McCat"
Movie.count
```
