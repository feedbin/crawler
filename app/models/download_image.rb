class DownloadImage

  def initialize(url, validate = true, mime_type = nil)
    @url = url
    @validate = validate
    @mime_type = mime_type || /image\/jp/
  end

  def file
    @file ||= begin
      response = HTTP.timeout(20).follow(max_hops: 5).get(@url)
      if headers_valid?(response)
        file = download_image(response)
      end
      file
    end
  end

  private

  def download_image(response)
    Pathname.new(File.join(Dir.tmpdir, "#{SecureRandom.hex}.jpg")).tap do |path|
      File.open(path, "wb") do |file|
        response.body.each { |chunk| file.write(chunk) }
      end
    end
  end

  def headers_valid?(response)
    if @validate
      response.content_type.mime_type =~ @mime_type && response.content_length > 100_000
    else
      response.content_type.mime_type =~ @mime_type
    end
  rescue
    false
  end

end