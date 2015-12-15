class Fetched

  def initialize(feed_id, feed_url, options = {})
    @feed_id = feed_id
    @feed_url= feed_url
    @options = options
  end

  def feed
    data = {}
    if parsed_feed
      data = parsed_feed.to_feed
      data.delete(:feed_url)
      data.delete(:hubs)
    end
    data
  end

  def entries
    parsed_feed ? parsed_feed.entries : []
  end

  def parsed_feed
    @parsed_feed ||= begin
      result = nil
      request = FeedRequest.new(url: @feed_url, options: request_options)
      if request.body
        result = ParsedFeed.new(request.body, request, @feed_url)
      end
      result
    rescue
      nil
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
      DateTime.parse(@options[:last_modified])
    rescue
      nil
    end
  end

  def etag
    @options[:etag]
  end

  def user_agent
    agent = "Feedbin feed-id:#{@feed_id}"
    if @options[:subscribers]
      agent += " - #{@options[:subscribers]} subscribers"
    end
    agent
  end

end
