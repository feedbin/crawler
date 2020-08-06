lock "3.14.1"

set :branch, "http"

set :application, "refresher"
set :repo_url, "git@github.com:feedbin/#{fetch(:application)}.git"
set :deploy_to, "/srv/apps/#{fetch(:application)}"

set :bundle_jobs, 4
set :log_level, :info

namespace :deploy do
  desc "Pause Sidekiq"
  task :quiet do
    on roles :all do
      execute :sudo, :systemctl, :reload, "refresher.target"
    rescue SSHKit::Command::Failed
      puts "No workers running"
    end
  end

  desc "Restart refresher processes"
  task :restart do
    on roles :all do
      execute :sudo, :systemctl, :restart, "refresher.target"
    rescue SSHKit::Command::Failed
      execute :sudo, :systemctl, :start, "refresher.target"
    end
  end

  desc "Stop services"
  task :stop_bg do
    on roles :all do
      invoke "deploy:quiet"

      sleep(10)

      begin
        execute :sudo, :stop, :workers
      rescue SSHKit::Command::Failed
      end
    end
  end
end

before "deploy", "deploy:quiet"
after "deploy:published", "deploy:restart"
