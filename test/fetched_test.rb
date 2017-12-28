require_relative 'test_helper'

class FetchedTest < Minitest::Test

  def setup
    options = {
      "last_modified" => Time.now.httpdate,
      "etag" => random_string,
      "subscriptions_count" => 10
    }

    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)

    url_json = "http://www.example.com/feed.json"
    stub_request_file("feed.json", url_json, {headers: {"Content-Type" => "application/json"}})

    @fetched_json = Fetched.new(1, url_json, options)
    @fetched = Fetched.new(1, url, options)
  end

  def test_should_get_feed
    assert_kind_of Hash, @fetched.feed
    assert_kind_of Hash, @fetched_json.feed
  end

  def test_should_get_entries
    assert @fetched.entries.length > 0
    assert @fetched_json.entries.length > 0
    @fetched.entries.each do |entry|
      assert_kind_of Feedkit::Parser::XMLEntry, entry
    end
    @fetched_json.entries.each do |entry|
      assert_kind_of Feedkit::Parser::JSONEntry, entry
    end
  end

  def test_should_parsed_feed
    assert_kind_of Feedkit::Parser::XMLFeed, @fetched.parsed_feed
    assert_kind_of Feedkit::Parser::JSONFeed, @fetched_json.parsed_feed
  end

  def test_should_get_status
    assert_equal 200, @fetched.status
    assert_equal 200, @fetched_json.status
  end

end
