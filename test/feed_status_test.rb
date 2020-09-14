require_relative "test_helper"

class RetryTest < Minitest::Test

  def setup
    flush
  end

  def test_should_be_retrying
    feed_id = 1
    Retry.new(feed_id).retry!
    assert(Retry.new(feed_id).retrying?, "retrying? should be true.")
  end

  def test_should_not_be_retrying
    feed_id = 1
    Retry.new(feed_id).retry!
    Retry.clear!(feed_id)
    assert(!Retry.new(feed_id).retrying?, "retrying? should be false.")
  end

  def test_should_get_count
    feed_id = 1
    Retry.new(feed_id).retry!
    assert_equal(1, Retry.new(feed_id).count)
  end
end
