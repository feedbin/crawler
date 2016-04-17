class Fetched

  def initialize(feed_id, feed_url, options = {})
    @feed_id = feed_id
    @feed_url= feed_url
    @options = options
    @status = nil
  end

  def feed
    data = {}
    if parsed_feed
      data = parsed_feed.to_feed
    end
    data
  end

  def entries
    parsed_feed ? parsed_feed.entries : []
  end

  def parsed_feed
    if @parsed_feed.nil?
      result = false
      body = request.body
      if body
        result = ParsedFeed.new(body, request, @feed_url)
        result.feed
      end
      @parsed_feed = result
    else
      @parsed_feed
    end
  rescue Feedjira::NoParserAvailable
    mark_dead
    @parsed_feed = false
  end

  def request
    @request ||= FeedRequest.new(url: @feed_url, options: request_options)
  end

  def status
    @status || request.status
  end

  private

  def request_options
    options = {}
    options[:user_agent] = user_agent
    options[:if_modified_since] = last_modified if last_modified
    options[:if_none_match] = etag if etag
    options
  end

  def last_modified
    @last_modified ||= begin
      DateTime.parse(@options["last_modified"])
    rescue
      nil
    end
  end

  def etag
    @options["etag"]
  end

  def user_agent
    agent = "Feedbin feed-id:#{@feed_id}"
    if @options["subscriptions_count"]
      agent += " - #{@options["subscriptions_count"]} subscribers"
    end
    agent
  end

  def mark_dead
    Sidekiq::Client.push(
      'args'  => [@feed_id],
      'class' => 'FeedSeemsDead',
      'queue' => 'feed_seems_to_be_dead'
    )
  end
end
