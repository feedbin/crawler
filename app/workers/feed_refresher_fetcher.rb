def create_entry(entry)
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
  new_entry
end

class FeedRefresherFetcher
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher
  
  def perform(feed_id, feed_url, etag, last_modified, subscribers = nil)
    options = {}
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
    
    feed_fetcher = FeedFetcher.new(feed_url)
    feedzirra = feed_fetcher.fetch_and_parse(options, feed_url)
    if feedzirra.respond_to?(:entries) && feedzirra.entries.length > 0
      update = {feed: {id: feed_id, etag: feedzirra.etag, last_modified: feedzirra.last_modified}, entries: []}
      results = {}
      Sidekiq.redis { |conn| 
        conn.pipelined do
          feedzirra.entries.each do |entry|
            results[entry._public_id_] = conn.hexists("entry:public_ids:#{entry._public_id_[0..4]}", entry._public_id_)
          end
        end
      }
      feedzirra.entries.first(500).each do |entry|
        # if it's not already in the database
        if results[entry._public_id_].value == false
          entry = create_entry(entry)
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
  
end

