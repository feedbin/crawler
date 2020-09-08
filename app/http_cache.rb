# frozen_string_literal: true

class HTTPCache

  ETAG = :etag
  LAST_MODIFIED = :last_modified
  CHECKSUM = :checksum

  def initialize(feed_id)
    @feed_id = feed_id
  end

  def save(response)
    values = {
      ETAG          => response.etag,
      LAST_MODIFIED => response.last_modified,
      CHECKSUM      => response.checksum
    }
    Cache.write(cache_key, options: {expires_in: 8 * 60 * 60}, values: values)
  rescue Redis::CommandError
    Sidekiq.logger.warn <<-EOD
    -------------------
    Redis::CommandError
    #{values.inspect}
    #{response.inspect}
    -------------------
    EOD
  end

  def etag
    cached[ETAG]
  end

  def last_modified
    cached[LAST_MODIFIED]
  end

  def checksum
    cached[CHECKSUM]
  end

  def cached
    @cached ||= begin
      Cache.read(cache_key)
    end
  end

  def cache_key
    "feed:#{@feed_id}:http"
  end

end
