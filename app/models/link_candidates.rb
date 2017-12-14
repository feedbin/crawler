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


  def initialize(url)
    @url = URI.parse(url)
  end

  def download
    download = nil
    attempt = nil
    attempt = DownloadImage.new(@url)
    if attempt.file
      processed_image = ProcessedImage.new(attempt.file)
      if processed_image.process
        download = {
          original_url: @url.to_s,
          processed_url: processed_image.url.to_s,
          width: processed_image.width,
          height: processed_image.height,
        }
      end
    end
    download
  rescue *NETWORK_EXCEPTIONS
    Librato.increment 'entry_image.exception'
    nil
  ensure
    attempt && attempt.file && File.exist?(attempt.file) && File.delete(attempt.file)
  end

end
