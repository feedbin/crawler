require_relative "test_helper"
class RedirectCacheTest < Minitest::Test

  def setup
    flush
  end

  def test_should_collapse_stable_redirects
    feed_id = 2
    final_url = "http://example.com/final"
    redirect1 = Redirect.new(feed_id, status: 301, from: "http://example.com", to: "http://example.com/second")
    redirect2 = Redirect.new(feed_id, status: 301, from: "http://example.com/second", to: final_url)


    (RedirectCache::PERSIST_AFTER).times do
      RedirectCache.new(feed_id).save([redirect1, redirect2])
    end

    assert_nil RedirectCache.new(feed_id).read

    RedirectCache.new(feed_id).save([redirect1, redirect2])

    assert_equal(final_url, RedirectCache.new(feed_id).read)
  end

  def test_should_not_temporary_redirects
    redirect1 = Redirect.new(1, status: 302, from: "http://example.com", to: "http://example.com/second")
    assert_nil RedirectCache.new(1).save([redirect1])
  end

  def test_should_not_save_empty_redirects
    feed_url = "http://example.com"
    assert_nil RedirectCache.new(1).save([])
  end
end
