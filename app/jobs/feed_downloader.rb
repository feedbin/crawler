# frozen_string_literal: true

class FeedDownloader
  include Sidekiq::Worker

  sidekiq_options queue: :feed_downloader, retry: false, backtrace: false

  def perform(feed_id, feed_url, subscribers, critical = false)
    @feed_id        = feed_id
    @feed_url       = feed_url
    @subscribers    = subscribers
    @critical       = critical
    @redirects      = []
    @saved_redirect = RedirectCache.read(feed_url)
    @feed_status    = FeedStatus.new(feed_id)
    @cached         = HTTPCache.new(feed_id)

    if @critical || @feed_status.ok?
      download
    else
      Sidekiq.logger.info "Skipping: attempts=#{@feed_status.count} next_attempt=#{Time.at(@feed_status.next_retry).utc.iso8601} id=#{@feed_id} url=#{@feed_url}"
    end
  end

  def download
    @response = begin
      request
    rescue Feedkit::ZlibError
      request(auto_inflate: false)
    end

    Sidekiq.logger.info "Downloaded status=#{@response.status} url=#{@feed_url}"
    parse unless @response.not_modified?(@cached.checksum)
    @feed_status.clear!
    RedirectCache.save(@redirects, feed_url: @feed_url)

    Sidekiq.logger.info "Redirect: real=#{@redirects.last&.to}: saved=#{@saved_redirect}" if @saved_redirect
  rescue Feedkit::Error => exception
    @feed_status.error!(exception)
    Sidekiq.logger.info "Feedkit::Error: attempts=#{@feed_status.count} exception=#{exception.inspect} id=#{@feed_id} url=#{@feed_url}"
  end

  def request(auto_inflate: true)
    Feedkit::Request.download(@feed_url,
      on_redirect:   on_redirect,
      last_modified: @cached.last_modified,
      etag:          @cached.etag,
      auto_inflate:  auto_inflate,
      user_agent:    "Feedbin feed-id:#{@feed_id} - #{@subscribers} subscribers"
    )
  end

  def on_redirect
    proc do |from, to|
      @redirects.push Redirect.new(@feed_id, status: from.status.code, from: from.uri.to_s, to: to.uri.to_s)
    end
  end

  def parse
    @response.persist!
    parser = @critical ? FeedParserCritical : FeedParser
    job_id = parser.perform_async(@feed_id, @feed_url, @response.path)
    Sidekiq.logger.info "Parse enqueued job_id: #{job_id}"
    @cached.save(@response)
  end

end

class FeedDownloaderCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader_critical, retry: false
  def perform(*args)
    FeedDownloader.new.perform(*args, true)
  end
end
