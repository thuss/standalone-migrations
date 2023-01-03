source 'https://rubygems.org'

gem 'rake', '>= 10.0'
gem 'activerecord', ENV['AR'] ? ENV['AR'].split(",") : [">= 6.0.0", "< 7.1.0"]
gem 'railties', ENV['AR'] ? ENV['AR'].split(",") : [">= 6.0.0", "< 7.1.0"]
gem 'nokogiri', "~> 1.14.pre"

group :dev do
  gem 'sqlite3', '~> 1.5'
  gem 'rspec', '>= 2.99.0'
  gem 'jeweler'
end
