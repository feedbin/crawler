namespace :deploy do
  desc "Restart refresher processes"
  task :restart do
    on roles :all do
      execute :sudo, :systemctl, :restart, "refresher.target"
    rescue SSHKit::Command::Failed
      execute :sudo, :systemctl, :start, "refresher.target"
    end
  end
end
