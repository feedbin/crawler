lock "3.4.0"

set :application, "image"
set :repo_url, "git@github.com:feedbin/#{fetch(:application)}.git"
set :deploy_to, "/srv/apps/#{fetch(:application)}"

set :bundle_jobs, 4
set :rbenv_type, :system
set :rbenv_ruby, "2.3.0"
set :log_level, :info

before "deploy", "deploy:quiet"
after "deploy:published", "deploy:restart"
