# frozen_string_literal: true

class FeedDownloader
  attr_accessor :retry_count
  include Sidekiq::Worker

  sidekiq_options queue: :feed_downloader, dead: false, backtrace: false

  sidekiq_retry_in do |count, exception|
    ([count, 8].max ** 4) + 15 + (rand(30) * (count + 1))
  end

  sidekiq_retries_exhausted do |message, exception|
    feed_id = message["args"].first
    Retry.clear!(feed_id)
  end

  def perform(feed_id, feed_url, subscribers, critical = false)
    @feed_id     = feed_id
    @feed_url    = feed_url
    @subscribers = subscribers
    @critical    = critical

    @retry       = Retry.new(feed_id)
    @cached      = HTTPCache.new(feed_id)

    if retrying?
      Sidekiq.logger.warn "Skip: count: #{@retry.count} url: #{feed_url}"
    else
      download
    end
  end

  def download
    @response = request
    @retry.clear!
    if @cached.checksum == @response.checksum
      Sidekiq.logger.warn "Download success checksum match: url: #{@feed_url}"
    else
      Sidekiq.logger.warn "Download success parsing: url: #{@feed_url}"
      parse
    end
  rescue Feedkit::NotModified
    Sidekiq.logger.warn "Feedkit::NotModified: url: #{@feed_url}"
    @retry.clear!
  rescue Feedkit::Error => exception
    @retry.retry!
    Sidekiq.logger.warn "Feedkit::Error: count: #{retry_count} url: #{@feed_url} message: #{exception.message}"
    raise
  rescue => exception
    Sidekiq.logger.warn <<-EOD
      Exception: #{exception.inspect}: #{@feed_url}
      Message: #{exception.message.inspect}
      Backtrace: #{exception.backtrace.inspect}
    EOD
  end

  def request
    etag          = @critical ? nil : @cached.etag
    last_modified = @critical ? nil : @cached.last_modified
    Feedkit::Request.download(@feed_url,
      on_redirect:   on_redirect,
      last_modified: last_modified,
      etag:          etag,
      user_agent:    "Feedbin feed-id:#{@feed_id} - #{@subscribers} subscribers"
    )
  end

  def on_redirect
    proc do |from, to|
      Sidekiq.logger.warn "Redirect: status: #{from.status.code} url: #{@feed_url} location: #{to.uri}"
    end
  end

  def parse
    @response.persist!
    parser = @critical ? FeedParserCritical : FeedParser
    parser.perform_async(@feed_id, @feed_url, @response.path)
    @cached.save(@response)
  end

  def retrying?
    retry_count.nil? && @retry.retrying?
  end
end

class FeedDownloaderCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader_critical, retry: false
  def perform(*args)
    FeedDownloader.new.perform(*args, true)
  end
end
