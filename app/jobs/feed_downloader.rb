# frozen_string_literal: true

class FeedDownloader
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher

  def perform(feed_id, feed_url, subscribers)
    @feed_id = feed_id
    @feed_url = feed_url
    @subscribers = subscribers

    download
  end

  def download
    @response = Feedkit::Request.download(@feed_url,
      on_redirect: on_redirect,
      etag: http_cache[:etag],
      last_modified: http_cache[:last_modified],
      user_agent: "Feedbin feed-id:#{@feed_id} - #{@subscribers} subscribers"
    )
    parse if changed?
  rescue Feedkit::NotModified

  rescue Feedkit::Error

  end

  def parse
    @response.persist!
    FeedParser.perform_async(@feed_id, @feed_url, @response.path)
    Cache.write(cache_key, {
      etag: @response.etag,
      last_modified: @response.last_modified,
      checksum: @response.checksum
    })
  end

  def changed?
    http_cache[:checksum] != @response.checksum
  end

  def on_redirect
    proc do |result, location|
      puts "result: #{result.inspect}"
      puts "location: #{location}"
    end
  end

  def http_cache
    @http_cache = Cache.read(cache_key)
  end

  def cache_key
    "feed:#{@feed_id}:http"
  end
end

class FeedDownloaderCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher_critical
  def perform(*args)
    FeedDownloader.new.perform(*args)
  end
end
