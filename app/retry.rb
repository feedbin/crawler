# frozen_string_literal: true

class Retry
  KEY = "refresher:retry_tracker"

  def initialize(feed_id)
    @feed_id = feed_id
  end

  def self.clear!(*args)
    new(*args).clear!
  end

  def clear!
    Sidekiq.redis do |redis|
      redis.hdel(KEY, @feed_id)
    end
  end

  def retry!
    Sidekiq.redis do |redis|
      redis.hincrby(KEY, @feed_id, 1)
    end
  end

  def retrying?
    Sidekiq.redis do |redis|
      redis.hexists(KEY, @feed_id)
    end
  end

  def count
    Sidekiq.redis do |redis|
      redis.hget(KEY, @feed_id)
    end
  end
end
