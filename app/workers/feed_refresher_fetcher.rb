class FeedRefresherFetcher
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher

  # Options: etag, last_modified, subscribers, xml, push_callback, hub_secret
  def perform(feed_id, feed_url, options = {})
    result = nil
    feed = { id: feed_id }
    if options[:xml]
      entries = Pushed.new(options[:xml], feed_url).entries
    else
      fetched = Fetched.new(feed_id, feed_url, options)
      entries = fetched.entries
      feed = feed.merge(fetched.feed)
      if options[:push_callback] && options[:hub_secret]
        feed = fetched.parsed_feed
        push = PubSubHubbub.new(feed.hubs, feed.self_url, options[:push_callback], options[:hub_secret], options[:subscribers])
        push.subscribe
      end
    end

    entries = FormattedEntries.new(entries)
    if entries.entries.any?
      update = {
        feed: feed,
        entries: entries.entries,
      }
      # puts update.inspect
      # Sidekiq::Client.push(
      #   'args'  => [update],
      #   'class' => 'FeedRefresherReceiver',
      #   'queue' => 'feed_refresher_receiver'
      # )
    end
  end

end

