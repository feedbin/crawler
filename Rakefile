require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/**/*_test.rb'
end

desc "Open an irb session preloaded with this library"
task :console do
  path = File.expand_path(File.dirname(__FILE__))
  sh "irb -rubygems -I #{path} -r ./app/boot"
end

task default: :test
