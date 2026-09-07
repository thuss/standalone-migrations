source 'https://rubygems.org'

gem 'rake', '>= 10.0'
gem 'activerecord', ENV['AR'] ? ENV['AR'].split(",") : [">= 7.2.0", "< 8.2"]
gem 'railties', ENV['AR'] ? ENV['AR'].split(",") : [">= 7.2.0", "< 8.2"]
gem 'logger'

group :dev do
  # Active Record 8.x requires sqlite3 >= 2.1, and the 7.2 adapter declares
  # `gem "sqlite3", ">= 1.4"`, so 2.x covers every supported Rails series.
  gem 'sqlite3', '>= 2.1'
  gem 'rspec', '>= 2.99.0'
end

# Only needed to cut a release. Excluded in CI via
# `bundle config set --local without release`.
group :release do
  gem 'jeweler'
end
