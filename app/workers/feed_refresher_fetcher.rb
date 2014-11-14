class FeedRefresherFetcher
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher

  def perform(feed_id, feed_url, etag, last_modified, subscribers = nil, body = nil, push_callback = nil, hub_secret = nil)
    feed_fetcher = FeedFetcher.new(feed_url)
    options = get_options(feed_id, etag, last_modified, subscribers, push_callback, hub_secret)

    source = Socket.gethostname
    if body
      source += '-push'
      feedzirra = feed_fetcher.parse(body, feed_url)
    else
      feedzirra = feed_fetcher.fetch_and_parse(options, feed_url)
    end

    if feedzirra.respond_to?(:entries) && feedzirra.entries.length > 0
      update = {feed: {id: feed_id, etag: feedzirra.etag, last_modified: feedzirra.last_modified}, entries: []}
      public_ids = feedzirra.entries.map {|entry| entry._public_id_}
      content_lengths = get_content_lengths(public_ids)
      feedzirra.entries.first(300).each do |entry|
        content_length = content_lengths[entry._public_id_]
        if content_length == nil
          entry = create_entry(entry, false, source)
          update[:entries].push(entry)
        elsif content_length && entry.content && entry.content.length != content_length
          entry = create_entry(entry, true)
          update[:entries].push(entry)
        end
      end
      if update[:entries].any?
        Sidekiq::Client.push(
          'args'  => [update],
          'class' => 'FeedRefresherReceiver',
          'queue' => 'feed_refresher_receiver'
        )
      end
    end
  end

  def get_options(feed_id, etag, last_modified, subscribers, push_callback, hub_secret)
    options = {}

    options[:feed_id] = feed_id
    options[:hub_secret] = hub_secret

    unless last_modified.blank?
      begin
        options[:if_modified_since] = DateTime.parse(last_modified)
      rescue Exception
      end
    end

    unless etag.blank?
      options[:if_none_match] = etag
    end

    options[:user_agent] = "Feedbin"
    unless subscribers.nil?
      options[:user_agent] = "Feedbin - #{subscribers} subscribers"
    end

    if push_callback
      options[:push_callback] = push_callback
    end

    options
  end

  def get_content_lengths(public_ids)
    content_lengths = {}

    Sidekiq.redis do |conn|
      conn.pipelined do
        public_ids.each do |public_id|
          content_lengths[public_id] = conn.hget("entry:public_ids:#{public_id[0..4]}", public_id)
        end
      end
    end

    content_lengths.each do |public_id, future|
      value = future.value.to_i
      if value == nil
        content_length = nil
      elsif value == 1
        content_length = false
      else
        begin
          content_length = future.value
        end
      end
      content_lengths[public_id] = content_length
    end

    content_lengths
  end

  def create_entry(entry, update = false, source = nil)
    new_entry = {}
    new_entry['author']        = entry.author
    new_entry['content']       = entry.content
    new_entry['title']         = entry.title
    new_entry['url']           = entry.url
    new_entry['entry_id']      = entry.entry_id
    new_entry['published']     = entry.try(:published)
    new_entry['updated']       = entry.try(:updated)
    new_entry['public_id']     = entry._public_id_
    new_entry['old_public_id'] = entry._old_public_id_
    new_entry['data']          = entry._data_
    if update
      new_entry['update'] = update
    end
    if source
      new_entry['source'] = source
    end
    new_entry
  end

end

