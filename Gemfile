source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
ruby '3.2.3'
gem 'rails', '~> 6.1.7', '>= 6.1.7.10'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

gem 'pg', '~> 1.1'
gem 'puma', '~> 5'
#gem 'redis', '~> 4.0'
gem 'redis-client', '~> 0.28.0'
#gem 'sidekiq', '~> 6.1'
gem 'sidekiq', '~> 7.3', '>= 7.3.9'
#gem 'sidekiq-scheduler', '~> 3.0'
gem 'sidekiq-scheduler', '~> 6.0', '>= 6.0.2'

#gem 'sidekiq-cron', '~> 2.4'


# HTTP Client
#gem 'faraday', '~> 1.10'
gem 'faraday', '>= 2.14.3'
#gem 'faraday_middleware', '~> 1.0'
#gem 'faraday_middleware', '>= 1.2.1'

# Circuit Breaker
#gem 'circuit_breaker', '~> 1.4'
gem 'circuitbox', '>= 2.0'
gem 'request_store', '~> 1.5'  # Pour le request_id



# JSON
gem 'jbuilder', '~> 2.7'
gem 'active_model_serializers', '~> 0.10.0'

# Auth
gem 'jwt', '~> 2.2'
gem 'bcrypt', '~> 3.1.7'

# Pagination
gem 'kaminari', '~> 1.2'

# CSV Export
gem 'csv'

# Utilities
gem 'dotenv-rails', '~> 2.7'
gem 'rack-cors', '~> 1.1'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 4.0'
  gem 'factory_bot_rails', '~> 6.1'
  gem 'faker', '~> 2.17'
end

group :test do
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.12'
end

group :development do
  gem 'listen', '~> 3.2'
  gem 'spring', '~> 2.1'
  gem 'spring-watcher-listen', '~> 2.0'
end