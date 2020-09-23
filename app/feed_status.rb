# frozen_string_literal: true

class FeedStatus
  def initialize(feed_id)
    @feed_id = feed_id
  end

  def self.clear!(*args)
    new(*args).clear!
  end

  def clear!
    Cache.delete(cache_key, errors_cache_key)
  end

  def error!(exception)
    @count = count + 1
    Cache.write(cache_key, {
      count: @count,
      failed_at: Time.now.to_i
    })
    Sidekiq.redis do |redis|
      redis.pipelined do
        redis.lpush(errors_cache_key, error_json(exception))
        redis.ltrim(errors_cache_key, 0, 25)
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

  def attempt_log
    @attempt_log ||= begin
      Sidekiq.redis do |redis|
        redis.lrange(errors_cache_key, 0, -1)
      end.map do |json|
        data = JSON.load(json)
        data["date"] = Time.at(data["date"])
        data
      end
    end
  end

  def error_json(exception)
    status = exception.respond_to?(:response) ? exception.response.status.code : nil
    JSON.dump({date: Time.now.to_i, class: exception.class, message: exception.message, status: status})
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
