source 'https://rubygems.org'

gem 'rake', '>= 10.0'
gem 'activerecord', ENV['AR'] ? ENV['AR'].split(",") : [">= 4.2.7", "< 5.3.0"]
gem 'railties', ENV['AR'] ? ENV['AR'].split(",") : [">= 4.2.7", "< 5.3.0"]

group :dev do
  gem 'sqlite3', '~> 1.3.6'
  gem 'rspec', '>= 2.99.0'
  gem 'jeweler'
end
