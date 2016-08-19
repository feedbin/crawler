require 'zlib'
require_relative 'test_helper'
require_relative '../app/models/feed_request'

class TestFeedRequest < Minitest::Test

  def test_get_body
    url = "http://www.example.com/atom.xml"
    body = random_string
    stub_request(:get, url).to_return(body: body)

    feed_request = FeedRequest.new(url: url)

    assert_equal body, feed_request.body
  end

  def test_get_gzipped_body
    url = "http://www.example.com/atom.xml"
    body = random_string

    response = {
      body: gzip(body),
      headers: {
        "Content-Encoding" => "gzip"
      }
    }
    stub_request(:get, url).to_return(response)

    feed_request = FeedRequest.new(url: url)

    assert_equal body, feed_request.body
  end

  private

  def gzip(string)
    string_io = StringIO.new("")
    zip = Zlib::GzipWriter.new(string_io)
    zip.write(string)
    zip.close
    string_io.string
  end

end
