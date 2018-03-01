class PageCandidates < Candidates

  include Helpers

  def find_image
    image = nil
    if domains_match?
      image = check_for_meta_images
    end
    image
  end

  def check_for_meta_images
    image = nil
    if page_checked?
      if cached = cached_image
        new_url = copy_image(cached)
        cached["processed_url"] = new_url
        image = cached
        Librato.increment 'entry_image.page_request.cache_hit'
      end
      Librato.increment 'entry_image.page_request.cached'
    else
      if download = try_candidates(page_candidates)
        image = download
        cache_image(download.to_json)
        Librato.increment 'entry_image.page_request.image_found'
      else
        cache_image("")
      end
    end
    image
  end

  def page_candidates
    candidates = []
    if check_page?
      Librato.increment 'entry_image.page_request'
      tags = find_meta_tags
      tags_found(tags.any?)
      candidates = find_meta_image_candidates(tags)
    else
      Librato.increment 'entry_image.page_request.skip'
    end
    candidates
  end

  def find_meta_tags
    response = HTTParty.get(@full_url, timeout: 4)
    document = Nokogiri::HTML5(response.body)
    document.search("meta[property='og:title'], meta[property='twitter:card'], meta[property='og:image'], meta[property='twitter:image']")
  rescue *NETWORK_EXCEPTIONS
    Librato.increment 'entry_image.exception'
    []
  end

  def find_meta_image_candidates(meta_tags)
    meta_tags.each_with_object([]) do |element, array|
      if ["twitter:image", "og:image"].include?(element["property"]) && !element["content"].nil?
        src = element["content"].strip
        candidate = ImageCandidate.new(src, "img")
        array.push(candidate)
      end
    end
  end

  def domains_match?
    host_one = URI(@full_url).host.split(".").last(2)
    host_two = URI(@site_url).host.split(".").last(2)
    host_one == host_two
  rescue
    false
  end

  def tags_found(found)
    if found
      $redis.set(feed_key, "true", ex: 86400, nx: true)
    else
      $redis.set(feed_key, "", ex: 86400, nx: true)
    end
  end

  def check_page?
    result = $redis.get(feed_key)
    result.nil? || result != ""
  end

  def cached_value
    @cached_value ||= $redis.get(image_cache_key)
  end

  def page_checked?
    cached_value
  end

  def cached_image
    if !cached_value.nil? && cached_value != ""
      JSON.parse(cached_value)
    else
      false
    end
  end

  def cache_image(value)
    $redis.set(image_cache_key, value)
  end

  def feed_key
    "feed_meta_presence:#{@feed_id}"
  end

  def image_cache_key
    "entry_image:#{Digest::SHA1.hexdigest(@full_url)}"
  end

end
