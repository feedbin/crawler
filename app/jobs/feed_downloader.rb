# frozen_string_literal: true

class FeedDownloader
  include Sidekiq::Worker

  sidekiq_options queue: :feed_downloader, retry: false, backtrace: false

  def perform(feed_id, feed_url, subscribers, critical = false)
    @feed_id     = feed_id
    @feed_url    = feed_url
    @subscribers = subscribers
    @critical    = critical
    @feed        = Feed.new(feed_id)

    download if @critical || @feed.ok?
  end

  def download
    request
  end

  def request(auto_inflate: true)
    parsed_url = Feedkit::BasicAuth.parse(@feed_url)
    url = @feed.redirect ? @feed.redirect : parsed_url.url
    Sidekiq.logger.info "Redirect: from=#{@feed_url} to=#{@feed.redirect} id=#{@feed_id}" if @feed.redirect

    t = Tempfile.new("url_", binmode: true)

    headers = {}.tap do |hash|
      hash["Accept-Encoding"] = "gzip"
      hash["If-Modified-Since"] = @feed.last_modified if @feed.last_modified
      hash["If-None-Match"] = @feed.etag if @feed.etag
    end

    Get.get(url, headers: headers) do |chunk|
      t.write(chunk)
    end
    t.flush
    t.rewind
  end

  def on_redirect
    proc do |from, to|
      @feed.redirects.push Redirect.new(@feed_id, status: from.status.code, from: from.uri.to_s, to: to.uri.to_s)
    end
  end

  def parse
    @response.persist!
    parser = @critical ? FeedParserCritical : FeedParser
    job_id = parser.perform_async(@feed_id, @feed_url, @response.path, @response.encoding.to_s)
    Sidekiq.logger.info "Parse enqueued job_id: #{job_id}"
    @feed.save(@response)
  end
end

class FeedDownloaderCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader_critical, retry: false
  def perform(*args)
    FeedDownloader.new.perform(*args, true)
  end
end
