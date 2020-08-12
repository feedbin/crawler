# frozen_string_literal: true

class FeedDownloader
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader, retry: false

  def perform(feed_id, feed_url, subscribers, critical = false)
    @feed_id     = feed_id
    @feed_url    = feed_url
    @subscribers = subscribers
    @critical    = critical
    @response    = download

    parse unless cached[:checksum] == @response.checksum
  rescue Feedkit::NotModified
    puts "Feedkit::NotModified"
    $redis.with do |redis|
      redis.expire(cache_key, ((1..8).to_a.sample * (1..60).to_a.sample * (1..60).to_a.sample))
    end
  rescue Feedkit::Error => e
    puts "Feedkit::Error: count: #{increment_error_count} url: #{feed_url} message: #{e.message}"
  rescue => e
    puts "Error: count: #{increment_error_count} url: #{feed_url} message: #{e.message}"
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
    parser = @critical ? FeedParserCritical : FeedParser
    parser.perform_async(@feed_id, @feed_url, @response.path)
    Cache.write(cache_key, options: {expires_in: 8 * 60 * 60}, values: {
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
    @cached ||= begin
      @critical ? {} : Cache.read(cache_key)
    end
  end

  def cache_key
    "feed:#{@feed_id}:http"
  end

  def increment_error_count
    $redis.with do |redis|
      redis.incr("feed:#{@feed_id}:error_count")
    end
  end
end

class FeedDownloaderCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader_critical, retry: false
  def perform(*args)
    FeedDownloader.new.perform(*args, true)
  end
end
