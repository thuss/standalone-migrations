source 'https://rubygems.org'

gem 'rake', '>= 10.0'
gem 'activerecord', ENV['AR'] ? ENV['AR'].split(",") : [">= 4.2.7", "< 5.2.0"]
gem 'railties', ENV['AR'] ? ENV['AR'].split(",") : [">= 4.2.7", "< 5.2.0"]

group :dev do
  gem 'sqlite3'
  gem 'rspec', '>= 2.0'
  gem 'jeweler'
end
