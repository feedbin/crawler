# frozen_string_literal: true

class HTTPCache

  ETAG = :etag
  LAST_MODIFIED = :last_modified
  CHECKSUM = :checksum

  def initialize(feed_id)
    @feed_id = feed_id
  end

  def save(response)
    Cache.write(cache_key, options: {expires_in: 8 * 60 * 60}, values: {
      ETAG          => response.etag,
      LAST_MODIFIED => response.last_modified,
      CHECKSUM      => response.checksum
    })
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
