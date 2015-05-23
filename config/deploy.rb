require "bundler/capistrano"

set :user,        'app'
set :application, "refresher"
set :use_sudo,    false

set :scm,           :git
set :repository,    "git@github.com:feedbin/refresher.git"
set :branch,        'master'
set :keep_releases, 5
set :deploy_via,    :remote_cache

set :ssh_options, { forward_agent: true }
set :deploy_to,   "/srv/apps/#{application}"

# TODO see if this can be removed if `sudo bundle` stops failing
set :bundle_cmd, "/usr/local/rbenv/shims/bundle"
set :worker_count, 8

# Gets rid of trying to link public/* directories
set :normalize_asset_timestamps, false

role :app, "refresher1.feedbin.com", "refresher2.feedbin.com", "refresher3.feedbin.com", "refresher4.feedbin.com", "refresher5.feedbin.com",
           "refresher6.feedbin.com", "refresher8.feedbin.com", "refresher9.feedbin.com", "refresher10.feedbin.com"

default_run_options[:pty] = true
default_run_options[:shell] = '/bin/bash --login'

namespace :foreman do
  desc 'Export the Procfile to Ubuntu upstart scripts'
  task :export do
    foreman_export = "foreman export --app #{application} --user #{user} --concurrency worker=#{worker_count} --log #{shared_path}/log upstart /etc/init"
    run "cd #{current_path} && sudo #{bundle_cmd} exec #{foreman_export}"
  end

  desc 'Start the application services'
  task :start do
    run "sudo start #{application}"
  end

  desc 'Stop the application services'
  task :stop do
    run "sudo stop #{application}"
  end

  desc 'Restart the application services'
  task :restart do
    run "sudo start #{application} || sudo restart #{application}"
  end
end

namespace :deploy do
  desc 'Start the application services'
  task :start do
    foreman.start
  end

  desc 'Stop the application services'
  task :stop do
    foreman.stop
  end

  desc 'Restart the application services'
  task :restart do
    foreman.restart
  end
end

desc 'Show logs'
task :logs do
  logs = [*1..8].map {|count| "-f #{shared_path}/log/worker-#{count}.log" }
  stream "tail #{logs.join(' ')}"
end

after 'deploy:update', 'foreman:export'
after "deploy:restart", "deploy:cleanup"
