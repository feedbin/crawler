# frozen_string_literal: true

class FeedStatus
  def initialize(feed_id)
    @feed_id = feed_id
  end

  def self.clear!(*args)
    new(*args).clear!
  end

  def self.error!(feed_id)
    new(feed_id).error!
  end

  def clear!
    Cache.delete(cache_key)
  end

  def error!
    Cache.write(cache_key, {
      count: count + 1,
      failed_at: Time.now.to_i
    })
  end

  def ok?
    Time.now.to_i > next_retry
  end

  def next_retry
    failed_at + backoff
  end

  def backoff
    multiplier = [count, 8].max
    multiplier = [multiplier, 23].min
    multiplier ** 4
  end

  def count
    cached[:count].to_i
  end

  def failed_at
    cached[:failed_at].to_i
  end

  def cached
    @cached ||= Cache.read(cache_key)
  end

  def cache_key
    "refresher_retry_#{@feed_id}"
  end
end
