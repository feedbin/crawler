require_relative 'test_helper'

class TestFeedRequest < Minitest::Test

  def test_get_body
    url = "http://www.example.com/atom.xml"
    body = random_string
    stub_request(:get, url).to_return(body: body)

    feed_request = FeedRequest.new(url: url)

    assert_equal body, feed_request.body
  end

  def test_get_gzipped_body
    url = "http://www.example.com"
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

  def test_should_be_xml
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    feed_request = FeedRequest.new(url: url)
    assert_equal :xml, feed_request.format
  end

  def test_should_be_html
    url = "http://www.example.com/atom.xml"
    body = random_string
    stub_request(:get, url).to_return(body: body)
    feed_request = FeedRequest.new(url: url)
    assert_equal :html, feed_request.format
  end

  def test_should_follow_redirects
    first_url = "http://www.example.com"
    last_url = "#{first_url}/final"
    body = random_string

    response = {
      status: 301,
      headers: {
        "Location" => last_url
      }
    }
    stub_request(:get, first_url).to_return(response)
    stub_request(:get, last_url)

    feed_request = FeedRequest.new(url: first_url)
    assert_equal last_url, feed_request.last_effective_url
  end

  def test_should_get_caching_headers
    url = "http://www.example.com/atom.xml"
    last_modified = Time.now
    etag = random_string

    response = {
      headers: {
        "Last-Modified" => last_modified.httpdate,
        "Etag" => etag
      }
    }
    stub_request(:get, url).to_return(response)
    feed_request = FeedRequest.new(url: url)

    assert_equal last_modified.httpdate, feed_request.last_modified.httpdate
    assert_equal etag, feed_request.etag
  end

  def test_should_not_be_modified_etag
    url = "http://www.example.com"
    etag = random_string
    status = 304

    request = {
      headers: {"If-None-Match" => etag}
    }
    stub_request(:get, url).with(request).to_return(status: status)
    feed_request = FeedRequest.new(url: url, options: {if_none_match: etag})

    assert_equal status, feed_request.status
  end

  def test_should_not_be_modified_last_modified
    url = "http://www.example.com"
    last_modified = Time.now
    status = 304

    request = {
      headers: {"If-Modified-Since" => last_modified.httpdate}
    }
    stub_request(:get, url).with(request).to_return(status: status)
    feed_request = FeedRequest.new(url: url, options: {if_modified_since: last_modified})

    assert_equal status, feed_request.status
  end

  def test_should_get_charset
    url = "http://www.example.com"
    charset = "utf-8"
    response = {
      headers: {
        "Content-Type" => "text/html; charset=#{charset}",
      }
    }
    stub_request(:get, url).to_return(response)
    feed_request = FeedRequest.new(url: url)

    assert_equal charset.upcase, feed_request.charset
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
