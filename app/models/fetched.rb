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
        if request.format == :json_feed
          result = ParsedJSONFeed.new(body, request, @feed_url)
        else
          result = ParsedXMLFeed.new(body, request, @feed_url)
        end
        result.feed
      end
      Librato.increment 'refresher.status', source: status.to_i
      @parsed_feed = result
    else
      @parsed_feed
    end
  rescue Feedjira::NoParserAvailable
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

end
