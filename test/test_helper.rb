require "coveralls"
Coveralls.wear!

ENV["REDIS_URL"] = "redis://localhost:7775"

require "minitest/autorun"
require "webmock/minitest"

redis_test_instance = IO.popen("redis-server --port 7775")
Minitest.after_run do
  puts "killing it"
  Process.kill("INT", redis_test_instance.pid)
end

require "sidekiq/testing"
Sidekiq::Testing.fake!

require_relative "../app/boot"

def flush
  Sidekiq::Worker.clear_all
  $redis.with do |redis|
    redis.flushdb
  end
end

def stub_request_file(file, url, options = {})
  file = File.join("test/support/www", file)
  defaults = {body: File.new(file), status: 200}
  stub_request(:get, url)
    .to_return(defaults.merge(options))
end

def load_xml
  File.read("test/support/www/atom.xml")
end

def random_string
  (0...50).map { ("a".."z").to_a[rand(26)] }.join
end
