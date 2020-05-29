# frozen_string_literal: true

class HTTPCache

  ETAG = "etag"
  LAST_MODIFIED = "last_modified"
  CHECKSUM = "checksum"

  def initialize(feed_id)
    @feed_id = feed_id
  end

  def etag
    cache[ETAG]
  end

  def last_modified
    cache[LAST_MODIFIED]
  end

  def checksum
    cache[CHECKSUM]
  end

  def cache
    @cache ||= begin
      $redis.with do |redis|
        redis.hgetall feed_cache_key
      end
    end
  end

  def update!(etag, last_modified, checksum)
    $redis.with do |redis|
      redis.mapped_hmset(feed_cache_key, {
        ETAG          => etag,
        LAST_MODIFIED => last_modified,
        CHECKSUM      => checksum
      })
    end
  end

  def cache_key
    "feed:#{@feed_id}:cache"
  end

end
