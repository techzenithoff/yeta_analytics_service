source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.7'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.7', '>= 6.1.7.10'
# Use sqlite3 as the database for Active Record
#gem 'sqlite3', '~> 1.4'
# Use Puma as the app server
#gem 'puma', '~> 5.0'
gem 'puma', '~> 3.11'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #gem 'spring'
   gem 'spring', '4.2.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Posgresql
#gem 'pg', '~> 1.1', '>= 1.1.3'


gem 'pg', '~> 1.5', '>= 1.5.9'
#gem 'rack', '~> 3.2', '>= 3.2.1'
#gem 'rack-cors', '~> 3.0'
gem 'rack-cors', '~> 1.1'
gem 'bcrypt', '~> 3.1', '>= 3.1.20'
gem 'jwt', '~> 3.1', '>= 3.1.2'
gem 'active_model_serializers', '~> 0.10.15'


gem 'pg_search', '~> 2.3'
gem 'friendly_id', '~> 5.2', '>= 5.2.5'
gem 'whenever', '~> 1.0'

gem 'concurrent-ruby', '1.3.4' 



group :development do
  gem "better_errors"
  gem "binding_of_caller"
  gem 'annotate', '~> 2.7', '>= 2.7.5'
  gem 'faker', '~> 1.9', '>= 1.9.3'
  
  #gem 'capistrano', '~> 3.10', '>= 3.10.2'
  gem 'capistrano', '~> 3.19', '>= 3.19.2'
  #gem 'capistrano-bundler', '~> 2.0', '>= 2.0.1'
  gem 'capistrano-bundler', '~> 2.1', '>= 2.1.1'
  # For rails requirement
  #gem 'capistrano-rails', '~> 1.3', '>= 1.3.1'
  gem 'capistrano-rails', '~> 1.7'
  gem 'capistrano-rails-collection', '~> 0.1.0'

  # For rvm
  #gem 'capistrano-rvm', '~> 0.1.2'
  #gem 'capistrano-rbenv', '~> 2.2'
  gem 'capistrano-rbenv', '~> 2.2'

  # For puma
  gem 'capistrano3-puma', '~> 3.1', '>= 3.1.1'
  #gem 'capistrano3-puma', '~> 6.2'
  #gem 'capistrano3-puma', '~> 5.0', '>= 5.0.4'
  #gem 'capistrano3-puma', github: "seuros/capistrano-puma"
  #gem 'capistrano-local-precompile', '~> 1.2.0', require: false

end


# For Api docs
gem 'rswag-api'
gem 'rswag-ui'

group :development, :test, :production do
  gem 'rspec-rails' # For rails
  gem 'rswag-specs'
end

gem 'faraday', '~> 1.10', '>= 1.10.3'

#Help to kill N+1 queries and unused eager loading.
gem 'bullet', '~> 7.2'
gem 'httparty', '~> 0.23.2'