class ItunesImage
  include Sidekiq::Worker
  include Helpers
  sidekiq_options queue: :images, retry: false

  def perform(entry_id, image_url, public_id)

    processed_url = cached_value(image_url)
    processed_url = copy_image(processed_url)

    if !processed_url
      response = HTTP.timeout(:global, write: 8, connect: 8, read: 8).follow(max_hops: 4).get(image_url)
      path = Pathname.new(File.join(Dir.tmpdir, "#{SecureRandom.hex}.bin")).tap do |path|
        File.open path, "wb" do |io|
          while (chunk = response.readpartial)
            io << chunk
          end
        end
      end
      processed_image = ProcessedItunesImage.new(path)
      processed_image.process
      processed_url = processed_image.url
      if processed_url
        cache(image_url, processed_url)
      end
    end

    if processed_url
      Sidekiq::Client.push(
        'args'  => [entry_id, nil, processed_url],
        'class' => 'ItunesImage',
        'queue' => 'default'
      )
    end

  end

  def cached_value(url)
    $redis.get(cache_key(url))
  end

  def cache(url, processed_url)
    $redis.set(cache_key(url), processed_url)
  end

  def cache_key(url)
    "itunes_image:#{Digest::SHA1.hexdigest(url)}"
  end

end
