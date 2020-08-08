# frozen_string_literal: true

class FeedDownloader
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader, retry: false

  def perform(feed_id, feed_url, subscribers, critical = false)
    @feed_id     = feed_id
    @feed_url    = feed_url
    @subscribers = subscribers
    @parser      = critical ? FeedParserCritical : FeedParser
    @response    = download

    parse unless cached[:checksum] == @response.checksum
  rescue Feedkit::NotModified

  rescue Feedkit::Error

  rescue

  end

  def download
    Feedkit::Request.download(@feed_url,
      on_redirect: on_redirect,
      etag: cached[:etag],
      last_modified: cached[:last_modified],
      user_agent: "Feedbin feed-id:#{@feed_id} - #{@subscribers} subscribers"
    )
  end

  def parse
    @response.persist!
    @parser.perform_async(@feed_id, @feed_url, @response.path)
    Cache.write(cache_key, {
      etag: @response.etag,
      last_modified: @response.last_modified,
      checksum: @response.checksum
    })
  end

  def on_redirect
    proc do |result, location|
    end
  end

  def cached
    @cached ||= Cache.read(cache_key)
  end

  def cache_key
    "feed:#{@feed_id}:http"
  end
end

class FeedDownloaderCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader_critical, retry: false
  def perform(*args)
    FeedDownloader.new.perform(*args, true)
  end
end
