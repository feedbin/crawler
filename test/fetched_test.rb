require_relative 'test_helper'

class FetchedTest < Minitest::Test

  def setup
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    options = {
      "last_modified" => Time.now.httpdate,
      "etag" => random_string,
      "subscriptions_count" => 10
    }
    @fetched = Fetched.new(1, url, options)
  end

  def test_should_get_feed
    assert_kind_of Hash, @fetched.feed
  end

  def test_should_get_entries
    assert @fetched.entries.length > 0
    @fetched.entries.each do |entry|
      assert_kind_of ParsedEntry, entry
    end
  end

  def test_should_parsed_feed
    assert_kind_of ParsedFeed, @fetched.parsed_feed
  end

  def test_should_get_status
    assert_equal 200, @fetched.status
  end

end
