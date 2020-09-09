require_relative "test_helper"
class RedirectCacheTest < Minitest::Test

  def setup
    flush
  end

  def test_should_collapse_stable_redirects
    feed_url = "http://username:password@example.com"
    final_url = "http://example.com/final"
    redirect1 = Redirect.new(1, status: 301, from: "http://example.com", to: "http://example.com/second")
    redirect2 = Redirect.new(1, status: 301, from: "http://example.com/second", to: final_url)


    (RedirectCache::PERSIST_AFTER).times do
      RedirectCache.save([redirect1, redirect2], feed_url: feed_url)
    end

    assert_nil RedirectCache.read(feed_url)

    RedirectCache.save([redirect1, redirect2], feed_url: feed_url)

    assert_equal(final_url, RedirectCache.read(feed_url))
  end

  def test_should_not_temporary_redirects
    redirect1 = Redirect.new(1, status: 302, from: "http://example.com", to: "http://example.com/second")
    assert_nil RedirectCache.save([redirect1], feed_url: "http://example.com")
  end

  def test_should_not_save_empty_redirects
    feed_url = "http://example.com"
    assert_nil RedirectCache.save([], feed_url: feed_url)
  end
end
