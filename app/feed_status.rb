# frozen_string_literal: true

class FeedStatus
  def initialize(feed_id)
    @feed_id = feed_id
  end

  def self.clear!(*args)
    new(*args).clear!
  end

  def clear!
    Cache.delete(cache_key)
  end

  def error!(exception)
    @count = count + 1
    Cache.write(cache_key, {
      count: @count,
      failed_at: Time.now.to_i
    })
    Sidekiq.redis do |redis|
      redis.pipelined do
        redis.zadd(errors_cache_key, Time.now.to_i, exception.inspect)
        redis.zremrangebyrank(errors_cache_key, 0, -25)
      end
    end
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
    @count ||= cached[:count].to_i
  end

  def failed_at
    cached[:failed_at].to_i
  end

  def cached
    @cached ||= Cache.read(cache_key)
  end

  def cache_key
    "refresher_status_#{@feed_id}"
  end

  def errors_cache_key
    "refresher_errors_#{@feed_id}"
  end
end
