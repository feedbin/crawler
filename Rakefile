require "rake/testtask"

path = __dir__

Rake::TestTask.new(:test) do |test|
  test.libs = []
  test.ruby_opts = ["-W0"]
  test.pattern = "test/**/*_test.rb"
end

task default: :test
