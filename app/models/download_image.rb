class DownloadImage

  def initialize(url, validate = true)
    @url = url
    @validate = validate
  end

  def file
    @file ||= begin
      file = nil
      options = {use_ssl: @url.scheme == "https", open_timeout: 5, read_timeout: 30}
      Net::HTTP.start(@url.host, @url.port, options) do |http|
        request = Net::HTTP::Get.new(@url.request_uri)
        request['Referer'] = "https://feedbin.com/"
        http.request(request) do |response|
          if headers_valid?(response.to_hash)
            file = download_image(response)
          end
        end
      end
      file
    end
  end

  private

  def download_image(response)
    Pathname.new(File.join(Dir.tmpdir, "#{SecureRandom.hex}.jpg")).tap do |path|
      File.open(path, "wb") do |file|
        response.read_body do |chunk|
          file.write(chunk)
        end
      end
    end
  end

  def headers_valid?(headers)
    if @validate
      headers["content-type"].first == "image/jpeg" && headers["content-length"].first.to_i > 20_000
    else
      headers["content-type"].first == "image/jpeg"
    end
  rescue
    false
  end

end