class Fetched
  def initialize(feed_id, feed_url, options = {})
    @feed_id = feed_id
    @feed_url = feed_url
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
        result = Feedkit::Feedkit.new.fetch_and_parse(@feed_url, request: request, base_url: @feed_url) || false
      end
      Librato.increment "refresher.status", source: status.to_i
      @parsed_feed = result
    else
      @parsed_feed
    end
  rescue Feedjira::NoParserAvailable
    @parsed_feed = false
  rescue Curl::Err::CurlError => e
    @parsed_feed = false
    @message = e.class.to_s
  end

  def request
    @request ||= Feedkit::Request.new(url: @feed_url, options: request_options)
  end

  def status
    @status || request.status
  end

  def status_message
    if parsed_feed == false
      @message || "ParseError"
    else
      status
    end
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
