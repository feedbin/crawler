# frozen_string_literal: true
require "sidekiq/api"

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

  def find
    entry = find_in_retries
    if !entry
      entry = find_in_queue("queue:feed_downloader")
    end
    if !entry
      entry = find_in_queue("queue:feed_downloader_critical")
    end
    JSON.load(entry) if entry
  end

  def find_in_retries
    Sidekiq.redis do |conn|
      conn.zscan_each("retry", match: "*#{@feed_id},*", count: 100) do |entry, score|
        return entry
      end
    end
  end

  def find_in_queue(queue)
    size = 100
    start = 0
    stop = size
    result = nil
    until (jobs = Sidekiq.redis { |conn| conn.lrange queue, ((start == 0) ? 0 : start + 1), stop}).empty?
      result = jobs.find {|job| job.include?("#{@feed_id},") }
      break unless result.nil?
      start = start + size
      stop = stop + size
    end
    result
  end
end
