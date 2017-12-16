class ImageCandidate
  YOUTUBE_URLS = [%r(https?://youtu\.be/(.+)), %r(https?://www\.youtube\.com/watch\?v=(.*?)(&|#|$)), %r(https?://www\.youtube\.com/embed/(.*?)(\?|$)), %r(https?://www\.youtube\.com/v/(.*?)(#|\?|$)), %r(https?://www\.youtube\.com/user/.*?#\w/\w/\w/\w/(.+)\b)]
  VIMEO_URL = %r(https?://player\.vimeo\.com/video/(.*?)(#|\?|$))
  INSTAGRAM_URL = %r(https?://www\.instagram\.com/p/(.*?)(/|#|\?|$))

  IGNORE_EXTENSIONS = [".gif", ".png", ".webp"]

  def initialize(src, type)
    @src = src
    @type = type
    @valid = false
    @url = nil

    if image?
      @url = image_candidate
    elsif iframe?
      @url = iframe_candidate
    end
  end

  def valid?
    return @valid
  end

  def original_url
    @original_url ||= begin
      if @url.respond_to?(:call)
        @url = @url.call
      end
      begin
        URI(@url)
      rescue
        nil
      end
    end
  end

  private

  def image?
    @type == "img"
  end

  def iframe?
    @type == "iframe"
  end

  def image_candidate
    if !IGNORE_EXTENSIONS.find { |extension| @src.include?(extension) }
      @valid = true
      lambda do
        begin
          response = HTTParty.head(@src, verify: false, timeout: 4)
          response.request.last_uri.to_s
        rescue
          nil
        end
      end
    end
  end

  def iframe_candidate
    uri = nil
    if YOUTUBE_URLS.find { |format| @src =~ format } && $1
      uri = youtube_uri($1)
      @valid = true
    elsif @src =~ VIMEO_URL && $1
      uri = vimeo_uri($1)
      @valid = true
    elsif @src =~ INSTAGRAM_URL && $1
      uri = instagram_uri($1)
      @valid = true
    end
    uri
  end

  def vimeo_uri(id)
    lambda do
      uri = nil
      query = Addressable::URI.new.tap do |addressable|
        addressable.query_values = {url: "https://vimeo.com/#{id}"}
      end.query

      options = {
        scheme: "https",
        host: "vimeo.com",
        path: "/api/oembed.json",
        query: query
      }

      response = HTTParty.get(URI::HTTP.build(options), timeout: 4)
      if response.code == 200
        uri = response.parsed_response["thumbnail_url"]
        uri = uri.gsub(/_\d+.jpg/, ".jpg")
      end

      uri
    end
  end

  def instagram_uri(id)
    lambda do
      query = Addressable::URI.new.tap do |addressable|
        addressable.query_values = {size: "l"}
      end.query


      "https://instagram.com/p/#{id}/media/?size=l"

      options = {
        scheme: "https",
        host: "instagram.com",
        path: "/p/#{id}/media/",
        query: query
      }

      response = HTTParty.get(URI::HTTP.build(options), timeout: 4, follow_redirects: true)
      response.request.last_uri.to_s
    end
  end

  def youtube_uri(id)
    "http://img.youtube.com/vi/#{id}/maxresdefault.jpg"
  end

end