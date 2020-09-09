# frozen_string_literal: true

class Retry
  def initialize(feed_id)
    @feed_id = feed_id
  end

  def self.clear!(*args)
    new(*args).clear!
  end

  def clear!
    Cache.delete(cache_key)
  end

  def retry!
    Cache.increment(cache_key, options: {expires_in: (5 * 24) * 60 * 60})
  end

  def retrying?
    count > 0
  end

  def count
    @count ||= Cache.count(cache_key)
  end

  def cache_key
    "refresher_retry_#{@feed_id}"
  end
end
