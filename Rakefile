desc "Open an irb session preloaded with this library"
task :console do
  path = File.expand_path(File.dirname(__FILE__))
  sh "irb -rubygems -I #{path} -r ./app/boot"
end
