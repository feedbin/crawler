class TwitterLinkImage
  include Sidekiq::Worker
  include Helpers
  sidekiq_options queue: :images, retry: false

  def perform(entry_id, feed_id, page_url, public_id)
    @public_id = "#{public_id}-twitter"

    processed_url = cached_value(page_url)

    if processed_url
      processed_url = copy_image(processed_url)
    else
      if attempt = PageCandidates.new(feed_id, page_url, page_url, page_url, "", @public_id, /image/).find_image
        processed_url = attempt["processed_url"]
        cache(page_url, processed_url)
      end
    end

    if processed_url
      Sidekiq::Client.push(
        'args'  => [entry_id, nil, processed_url],
        'class' => 'TwitterLinkImage',
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
    "twitter_link_image:#{Digest::SHA1.hexdigest(url)}"
  end

end
