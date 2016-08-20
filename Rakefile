require 'rake/testtask'

path = File.expand_path(File.dirname(__FILE__))

Rake::TestTask.new(:test) do |test|
  test.libs = []
  test.ruby_opts = ['-W0']
  test.pattern = 'test/**/*_test.rb'
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I #{path} -r ./app/boot"
end

task default: :test
