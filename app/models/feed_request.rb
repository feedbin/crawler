class FeedRequest

  attr_reader :url

  def initialize(url:, clean: false, options: {})
    @url = url
    @options = options
    if clean
      @url = clean_url
    end
  end

  def body
    @body ||= begin
      result = response.body
      if gzipped?
        result = gunzip(result)
      end
      result = result.lstrip
      if result == ""
        result = nil
      end
      result
    rescue
      nil
    end
  end

  def format
    if body && /^\s*<(?:!DOCTYPE\s+)?html[\s>]/i === body[0, 512]
      :html
    else
      :xml
    end
  end

  def last_effective_url
    @last_effective_url ||= response.uri.to_s
  end

  def last_modified
    @last_modified ||= begin
      Time.parse(headers[:last_modified])
    rescue
      nil
    end
  end

  def etag
    @etag ||= begin
      content = headers[:etag]
      if content && content.match(/^"/) && content.match(/"$/)
        content = content.gsub(/^"/, "").gsub(/"$/, "")
      end
      content
    end
  end

  def status
    @status ||= response.status.code
  end

  def headers
    @headers ||= begin
      response.headers.each_with_object({}) do |(header, value), hash|
        header = header.downcase.gsub("-", "_").to_sym
        hash[header] = value
      end
    end
  end

  private

  def gunzip(string)
    string = StringIO.new(string)
    gz =  Zlib::GzipReader.new(string)
    result = gz.read
    gz.close
    result
  rescue Zlib::GzipFile::Error
    string
  end

  def gzipped?
    headers[:content_encoding] =~ /gzip/i
  end

  def response
    @response ||= begin
      request_headers = {}
      request_headers[:user_agent] = @options[:user_agent] || "Feedbin"
      request_headers[:accept_encoding] = "gzip"
      request_headers[:if_modified_since] = @options[:if_modified_since].httpdate if @options.has_key?(:if_modified_since)
      request_headers[:if_none_match] = @options[:if_none_match] if @options.has_key?(:if_none_match)
      HTTP.follow.headers(request_headers).timeout(write: 10, connect: 10, read: 20).get(@url)
    end
  end

  def clean_url
    url = @url
    url = url.strip
    url = url.gsub(/^ht*p(s?):?\/*/, 'http\1://')
    url = url.gsub(/^feed:\/\//, 'http://')
    if url !~ /^https?:\/\//
      url = "http://#{url}"
    end
    url
  end

end