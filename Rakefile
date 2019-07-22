require 'rake/testtask'

path = File.expand_path(File.dirname(__FILE__))

Rake::TestTask.new(:test) do |test|
  test.libs = []
  test.ruby_opts = ['-W0']
  test.pattern = 'test/**/*_test.rb'
end

task default: :test
