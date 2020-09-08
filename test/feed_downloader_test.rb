require_relative "test_helper"

class FeedDownloaderTest < Minitest::Test
  def setup
    flush
  end

  def test_should_schedule_feed_parser
    url = "http://example.com/atom.xml"
    stub_request_file("atom.xml", url)

    assert_equal 0, FeedParser.jobs.size
    FeedDownloader.new.perform(1, url, 10)
    assert_equal 1, FeedParser.jobs.size

    FeedDownloader.new.perform(1, url, 10)
    assert_equal 1, FeedParser.jobs.size, "Should not parse again because checksum matches"
  end

  def test_should_schedule_critical_feed_parser
    url = "http://example.com/atom.xml"
    stub_request_file("atom.xml", url)

    assert_equal 0, FeedParserCritical.jobs.size
    FeedDownloaderCritical.new.perform(1, url, 10)
    assert_equal 1, FeedParserCritical.jobs.size
  end

  def test_should_send_user_agent
    url = "http://example.com/atom.xml"
    stub_request_file("atom.xml", url).with(headers: {"User-Agent" => "Feedbin feed-id:1 - 10 subscribers"})
    FeedDownloader.new.perform(1, url, 10)
  end

  def test_should_send_authorization
    username = "username"
    password = "password"
    url = "http://#{username}:#{password}@example.com/atom.xml"

    stub_request(:get, "http://example.com/atom.xml").with(headers: {"Authorization" => "Basic #{Base64.strict_encode64("#{username}:#{password}")}"})
    FeedDownloader.new.perform(1, url, 10)
  end

  def test_should_do_nothing_if_not_modified
    feed_id = 1
    etag = "etag"
    last_modified = "last_modified"
    Cache.write("feed:#{feed_id}:http", values: {
      etag: etag,
      last_modified: last_modified,
      checksum: nil
    })

    url = "http://example.com/atom.xml"
    stub_request(:get, url).with(headers: {"If-None-Match" => etag, "If-Modified-Since" => last_modified}).to_return(status: 304)
    FeedDownloader.new.perform(feed_id, url, 10)
    assert_equal 0, FeedParser.jobs.size
  end

  def test_should_retry_if_rate_limited
    feed_id = 1

    url = "http://example.com/atom.xml"
    stub_request(:get, url).to_return(status: 429)

    assert_raises Feedkit::Error do
      FeedDownloader.new.perform(feed_id, url, 10)
    end

    assert Retry.new(feed_id).retrying?, "Should be marked as retrying"
  end

  def test_should_ignore_cache_when_critical
    feed_id = 1
    etag = "etag"
    last_modified = "last_modified"
    Cache.write("feed:#{feed_id}:http", values: {
      etag: etag,
      last_modified: last_modified,
      checksum: nil
    })

    url = "http://example.com/atom.xml"
    stub_request(:get, url).to_return do |request|
      if request.headers["If-None-Match"] || request.headers["If-Modified-Since"]
        {status: 304}
      else
        {status: 200}
      end
    end

    FeedDownloader.new.perform(feed_id, url, 10)
    assert_equal 0, FeedParser.jobs.size

    FeedDownloaderCritical.new.perform(feed_id, url, 10)
    assert_equal 1, FeedParserCritical.jobs.size
  end

  def test_should_clear_retry
    feed_id = 1
    args = [feed_id, "http://example.com", 10]

    Retry.new(feed_id).retrying?
    FeedDownloader.new().sidekiq_retries_exhausted_block.call({"args" => args}, Feedkit::Error)

    refute Retry.new(feed_id).retrying?, "Should not retry after sidekiq_retries_exhausted is called"
  end


  def test_should_get_a_number
    result1 = FeedDownloader.new().sidekiq_retry_in_block.call(1, Feedkit::Error)
    result2 = FeedDownloader.new().sidekiq_retry_in_block.call(10, Feedkit::Error)

    assert result1.is_a?(Integer)
    assert result1 > 60 * 60
    assert result2 > result1
  end

  def test_should_follow_redirects
    first_url = "http://www.example.com"
    last_url = "#{first_url}/final"
    body = random_string

    response = {
      status: 301,
      headers: {
        "Location" => "/final"
      }
    }
    stub_request(:get, first_url).to_return(response)
    stub_request(:get, last_url)

    FeedDownloader.new.perform(1, first_url, 10)
  end



end
