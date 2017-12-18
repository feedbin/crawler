class LinkCandidates
  NETWORK_EXCEPTIONS = [Encoding::InvalidByteSequenceError,
                        Encoding::UndefinedConversionError,
                        Errno::ECONNRESET,
                        HTTParty::RedirectionTooDeep,
                        Net::OpenTimeout,
                        Net::ReadTimeout,
                        OpenSSL::SSL::SSLError,
                        Timeout::Error,
                        URI::InvalidURIError,
                        Zlib::DataError]


  def initialize(urls)
    @urls = urls
  end

  def download
    @urls.each do |url|
      url = URI.parse(url)
      if data = perform(url)
        return data
      end
    end
    return nil
  end

  def perform(url)

    image_data = nil
    attempt = nil

    candidate = ImageCandidate.new(url.to_s, "iframe")
    if candidate.valid?
      attempt = DownloadImage.new(candidate.original_url, false)
    else
      attempt = DownloadImage.new(url, false)
    end

    if attempt.file
      processed_image = ProcessedImage.new(attempt.file, false)
      if processed_image.process
        image_data = {
          original_url: url.to_s,
          processed_url: processed_image.url.to_s,
          width: processed_image.width,
          height: processed_image.height,
        }
      end
    end
    image_data
  rescue *NETWORK_EXCEPTIONS
    Librato.increment 'entry_image.exception'
    nil
  ensure
    attempt && attempt.file && File.exist?(attempt.file) && File.delete(attempt.file)
  end

end
