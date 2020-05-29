# frozen_string_literal: true

class FeedDownloader
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher

  def perform(feed_id, feed_url, username, password, subscribers)
    @feed_id = feed_id
    @feed_url = feed_url
    @username = username
    @password = password
    @subscribers = subscribers
    @http_cache = HTTPCache.new(feed_id)

    download
  end

  def download
    options = Feedkit::RequestOptions.new(
      etag: @http_cache.etag,
      last_modified: @http_cache.last_modified,
      user_agent: "Feedbin feed-id:#{@feed_id} - #{@subscribers} subscribers",
      username: @username,
      password: @password
    )
    @response = Feedkit::Request.download(@feed_url, options: options, on_redirect: on_redirect)
    parse_feed if feed_changed?
  end

  def parse_feed
    @response.persist!

    ParseFeed.perform_async(@feed_id, @feed_url, @response.path, @response.file_format)

    @http_cache.update!(@response.etag, @response.last_modified, @response.checksum)
  end

  def on_redirect
    proc do |result, location|
      puts "result: #{result.inspect}"
      puts "location: #{location}"
    end
  end

  def feed_changed?
    @http_cache.checksum != @response.checksum
  end
end


class FeedDownloaderCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher_critical
  def perform(*args)
    FeedDownloader.new.perform(*args)
  end
end
