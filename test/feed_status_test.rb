require_relative "test_helper"

class FeedStatusTest < Minitest::Test

  def setup
    flush
  end

  def test_should_not_be_ok
    feed_id = 1
    FeedStatus.new(feed_id).error!
    refute FeedStatus.new(feed_id).ok?, "ok? should be false."
  end

  def test_should_be_ok
    feed_id = 1
    FeedStatus.error!(feed_id)
    FeedStatus.clear!(feed_id)
    assert FeedStatus.new(feed_id).ok?, "ok? should be true."
  end

  def test_should_get_count
    feed_id = 1
    FeedStatus.new(feed_id).error!
    FeedStatus.new(feed_id).error!
    assert_equal(2, FeedStatus.new(feed_id).count)
  end

  def test_should_be_ok_after_timeout
    feed_id = 1

    FeedStatus.error!(feed_id)

    one_hour = 60 * 60
    one_hour_from_now = Time.now.to_i + one_hour
    two_hours_ago = Time.now.to_i - one_hour - one_hour

    feed_status = FeedStatus.new(feed_id)

    assert feed_status.next_retry > one_hour_from_now

    Cache.write(feed_status.cache_key, { failed_at: two_hours_ago })

    assert FeedStatus.new(feed_id).ok?, "Status should be ok after rewinding failed_at"
  end
end
