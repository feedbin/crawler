require "minitest/autorun"
require "webmock/minitest"

unless ENV["CI"]
  socket = Socket.new(:INET, :STREAM, 0)
  socket.bind(Addrinfo.tcp("127.0.0.1", 0))
  port = socket.local_address.ip_port
  socket.close

  port = 7775

  ENV["REDIS_URL"] = "redis://localhost:%d" % port
  redis_test_instance = IO.popen("redis-server --port %d --save '' --appendonly no" % port)

  Minitest.after_run do
    Process.kill("INT", redis_test_instance.pid)
  end
end

require "sidekiq/testing"
Sidekiq::Testing.fake!
Sidekiq.logger.level = Logger::WARN

require_relative "../app/boot"

ENV["AWS_ACCESS_KEY_ID"] = "AWS_ACCESS_KEY_ID"
ENV["AWS_SECRET_ACCESS_KEY"] = "AWS_SECRET_ACCESS_KEY"
ENV["AWS_S3_BUCKET"] = "images"

def flush
  Sidekiq::Worker.clear_all
  Sidekiq.redis do |redis|
    redis.flushdb
  end
end

def support_file(file_name)
  path = File.join Dir.tmpdir, SecureRandom.hex
  FileUtils.cp File.join("test/support/www", file_name), path
  path
end

def stub_request_file(file, url, options = {})
  defaults = {body: File.new(support_file(file)), status: 200}
  stub_request(:get, url)
    .to_return(defaults.merge(options))
end

def aws_copy_body
  <<~EOT
    <?xml version="1.0" encoding="UTF-8"?>
    <CopyObjectResult>
       <ETag>string</ETag>
       <LastModified>Tue, 02 Mar 2021 12:58:45 GMT</LastModified>
    </CopyObjectResult>
  EOT
end

class EntryImage
  include Sidekiq::Worker
  def perform(*args)
  end
end
