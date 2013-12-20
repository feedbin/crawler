class FeedRefresherFetcher
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher

  def perform(feed_id, feed_url, etag, last_modified, subscribers = nil, body = nil, push_callback = nil, hub_secret = nil)
    feed_fetcher = FeedFetcher.new(feed_url)
    options = get_options(feed_id, etag, last_modified, subscribers, push_callback, hub_secret)
    if body
      feedzirra = feed_fetcher.parse(body, feed_url)
    else
      feedzirra = feed_fetcher.fetch_and_parse(options, feed_url)
    end

    if feedzirra.respond_to?(:entries) && feedzirra.entries.length > 0
      update = {feed: {id: feed_id, etag: feedzirra.etag, last_modified: feedzirra.last_modified}, entries: []}
      public_ids = feedzirra.entries.map {|entry| entry._public_id_}
      updated_dates = get_updated_dates(public_ids)
      feedzirra.entries.first(300).each do |entry|
        entry_updated = updated_dates[entry._public_id_]
        if entry_updated == nil
          entry = create_entry(entry)
          update[:entries].push(entry)
        elsif entry_updated && entry.try(:updated) && entry.updated > entry_updated
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
    $librato_queue.add(refresher_performance: {type: :counter, value: 1, source: Socket.gethostname}) if $librato_queue
  end

  def get_options(feed_id, etag, last_modified, subscribers, push_callback, hub_secret)
    options = {}

    options[:feed_id] = feed_id
    options[:hub_secret] = hub_secret

    unless last_modified.blank?
      begin
        options[:if_modified_since] = DateTime.parse(last_modified)
      rescue Exception => e
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

  def get_updated_dates(public_ids)
    updated_dates = {}
    Sidekiq.redis { |conn|
      conn.pipelined do
        public_ids.each do |public_id|
          updated_dates[public_id] = conn.hget("entry:public_ids:#{public_id[0..4]}", public_id)
        end
      end
    }
    updated_dates.each do |public_id, future|
      value = future.value
      if value == nil
        date = nil
      elsif value == '1'
        date = false
      else
        begin
          date = Time.parse(future.value)
        rescue Exception
          date = false
        end
      end
      updated_dates[public_id] = date
    end
    updated_dates
  end

  def create_entry(entry, update = false)
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
    new_entry
  end

end

