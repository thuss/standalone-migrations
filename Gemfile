source 'https://rubygems.org'

gem 'rake', '>= 10.0'
gem 'activerecord', ENV['AR'] ? ENV['AR'].split(",") : [">= 6.0.0", "< 8.1"]
gem 'railties', ENV['AR'] ? ENV['AR'].split(",") : [">= 6.0.0", "< 8.1"]
gem 'nokogiri', "~> 1.14"

if ENV['AR']
  ar_version = ENV['AR'].split(",").last.match(/\d+\.\d+/)[0]

  sqlite3_version = case Gem::Version.new(ar_version)
                    # Active Record 8.x requires sqlite3 >= 2.1
                    when Gem::Version.new("8.0").. then ">= 2.1"
                    # Active Record 7.x requires sqlite3 >= 1.4
                    when Gem::Version.new("7.0")...Gem::Version.new("8.0") then ">= 1.4"
                    else "< 1.7"
                    end
else
  sqlite3_version = "< 1.7"
end

group :dev do
  gem 'sqlite3', sqlite3_version
  gem 'rspec', '>= 2.99.0'
  gem 'jeweler'
end
