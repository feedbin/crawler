class DownloadCache
  include Helpers

  attr_reader :storage_url

  def initialize(url, public_id:, preset_name:)
    @url = url
    @public_id = public_id
    @preset_name = preset_name
    @storage_url = nil
  end

  def self.copy(url, **args)
    instance = new(url, **args)
    instance.copy
    instance
  end

  def copy
    @storage_url = copy_image unless storage_url.nil? || storage_url == false
  end

  def copied?
    !!@storage_url
  end

  def storage_url
    @storage_url ||= cache[:storage_url]
  end

  def download?
    !previously_attempted? && storage_url != false
  end

  def previously_attempted?
    !cache.empty?
  end

  def save(url)
    @cache = {storage_url: url}
    Cache.write(cache_key, @cache, options: {expires_in: 7 * 24 * 60 * 60})
  end

  def cache
    @cache ||= begin
      Cache.read(cache_key)
    end
  end

  def cache_key
    "image_processed_#{@preset_name}_#{Digest::SHA1.hexdigest(@url)}"
  end

  def copy_image
    url = URI.parse(storage_url)
    source_object_name = url.path[1..-1]
    Fog::Storage.new(STORAGE_OPTIONS).copy_object(ENV["AWS_S3_BUCKET"], source_object_name, ENV["AWS_S3_BUCKET"], image_name, storage_options)
    final_url = url.path = "/#{image_name}"
    url.to_s
  rescue Excon::Error::NotFound
    false
  end
end
