class Throttle

  TIMEOUT = 60 * 60

  def initialize(feed_url, last_download)
    @feed_url = feed_url
    @last_download = last_download
  end

  def self.throttled?(*args)
    new(*args).throttled?
  end

  def throttled?
    throttled_hosts.include?(host) && downloaded_recently?
  end

  def downloaded_recently?
    return nil if @last_download.nil?
    (Time.now.to_i - @last_download) < TIMEOUT
  end

  def time_remaining
    "#{TIMEOUT - (Time.now.to_i - @last_download)}s"
  end

  def throttled_hosts
    ENV["THROTTLED_HOSTS"]&.split(",") || []
  end

  def host
    Addressable::URI.heuristic_parse(@feed_url).host.split(".").last(2).join(".")
  rescue
    nil
  end
end