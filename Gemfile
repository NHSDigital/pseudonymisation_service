source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.0', '>= 6.0.3.5'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1', '>= 4.3.5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Compute secure password hashes:
gem 'bcrypt', '~> 3.1.7'
# Build interactive terminal prompts:
gem 'highline'
# Authorisation library:
gem 'cancancan'

# libxml wrapper:
gem 'nokogiri', '~> 1.11'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Provides pseudonymisation implementations:
gem 'ndr_pseudonymise', '~> 0.4.0'

# Faster logging for bulk requests:
gem 'activerecord-import'

# Send stats to prometheus:
gem 'ndr_stats'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]

  gem 'ndr_dev_support'
  gem 'prometheus-client', '~> 0.9.0' # signature changes
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'mocha'
end
