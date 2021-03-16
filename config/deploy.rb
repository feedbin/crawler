set :application, "image"
set :repo_url, "git@github.com:feedbin/#{fetch(:application)}.git"
set :deploy_to, "/srv/apps/#{fetch(:application)}"
set :branch, "updates"

set :bundle_jobs, 4
set :log_level, :info

namespace :deploy do
  desc "Pause Sidekiq"
  task :quiet do
    on roles :all do
      execute :sudo, :systemctl, :reload, "image.target"
    rescue SSHKit::Command::Failed
      puts "No workers running"
    end
  end

  desc "Restart image processes"
  task :restart do
    on roles :all do
      execute :sudo, :systemctl, :restart, "image.target"
    rescue SSHKit::Command::Failed
      execute :sudo, :systemctl, :start, "image.target"
    end
  end

  desc "Stop services"
  task :stop_bg do
    on roles :all do
      invoke "deploy:quiet"

      sleep(10)

      begin
        execute :sudo, :systemctl, :stop, "image.target"
      rescue SSHKit::Command::Failed
      end
    end
  end
end

before "deploy", "deploy:quiet"
after "deploy:published", "deploy:restart"
