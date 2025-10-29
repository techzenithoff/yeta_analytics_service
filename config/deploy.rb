# config valid for current version and patch releases of Capistrano
lock "~> 3.19.1"


set :stages, %w(production staging)
set :default_stage, "production"

set :application, "yeta_watch_history_service"
set :repo_url, "https://github.com/techzenithoff/yeta-watch-history-service.git"
set :ssh_options, { auth_methods: %w(password), password: "AMOSXZIBITDE88" }

set :git_http_username, 'techzenithoff'
ask(:github_token, "github_token", echo: false)
set :git_http_password, fetch((:github_token))

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
 #set :deploy_to, "/home/ubuntu/acres-app"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
 #append :linked_files, "config/database.yml", "config/master.key", "config/meta.yml"
 append :linked_files, "config/database.yml", "config/master.key", "config/storage.yml"

# Default value for linked_dirs is []
#append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
 append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "public/storage", "storage"

 #set :nginx_config_name, "acres"
 #set :nginx_server_name, "acres"
 #set :puma_workers, 1

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

#set :default_env, { rvm_bin_path: '~/.rvm/bin' }


# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

# For rbenvu usage
# config/deploy.rb
set :rbenv_type, :user # or :system, or :fullstaq (for Fullstaq Ruby), depends on your rbenv setup
set :rbenv_ruby, '3.0.7'

# in case you want to set ruby version from the file:
# set :rbenv_ruby, File.read('.ruby-version').strip

set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
#set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_map_bins, %w{rake gem bundle ruby rails puma pumactl}
#set :rbenv_map_bins, %w(rake gem bundle ruby rails puma pumactl sidekiq sidekiqctl)
set :rbenv_roles, :all # default value


set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }





#Tasks

=begin
namespace :deploy do
  

  before :published, :systemd
  desc 'systemd integration'
  task :systemd do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within shared_path do
        execute "sudo cp #{shared_path}/config/puma.service /etc/systemd/system/puma.service"
        execute "sudo cp #{shared_path}/config/puma-init /usr/bin/puma-init"
        execute "sudo systemctl daemon-reload"
        execute "sudo systemctl restart puma"
      end
    end
  end
end
=end

#Uploading your master.key
namespace :deploy do
  namespace :check do
    before :linked_files, :set_master_key do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/master.key ]")
          upload! 'config/master.key', "#{shared_path}/config/master.key"
        end
      end
    end
  end
end


#Uploading your database.yml
namespace :deploy do
  namespace :check do
    before :linked_files, :set_database do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/database.yml ]")
          upload! 'config/database.yml', "#{shared_path}/config/database.yml"
        end
      end
    end
  end
end

#Uploading your storage.yml
namespace :deploy do
  namespace :check do
    before :linked_files, :set_storage do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/storage.yml ]")
          upload! 'config/storage.yml', "#{shared_path}/config/storage.yml"
        end
      end
    end
  end
end

