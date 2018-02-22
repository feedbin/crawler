class FeedRefresherFetcher
  include Sidekiq::Worker
  include RecordStatus
  sidekiq_options queue: :feed_refresher_fetcher

  # Options: etag, last_modified, subscriptions_count, xml, push_callback, hub_secret, push_mode, record_status
  def perform(feed_id, feed_url, options = {})
    feed = { id: feed_id }
    if options["xml"]
      entries = Pushed.new(options["xml"], feed_url).entries
    else
      fetched = Fetched.new(feed_id, feed_url, options)
      entries = fetched.entries
      feed = feed.merge(fetched.feed)
      if options["record_status"]
        record_status(feed_id, fetched.status_message)
      end
      if fetched.parsed_feed && options["push_callback"] && options["hub_secret"]
        push = PubSubHubbub.new(
          fetched.parsed_feed.hubs,
          fetched.parsed_feed.self_url,
          options["push_callback"],
          options["hub_secret"],
          options["subscriptions_count"]
        )
        if options["push_mode"] == "subscribe"
          push.subscribe
        elsif options["push_mode"] == "unsubscribe"
          push.unsubscribe
        end
      end
    end

    formatted_entries = FormattedEntries.new(entries)
    if !formatted_entries.new_or_changed.empty?
      update = {
        feed: feed,
        entries: formatted_entries.new_or_changed,
      }
      Sidekiq::Client.push(
        'args'  => [update],
        'class' => 'FeedRefresherReceiver',
        'queue' => 'feed_refresher_receiver'
      )
    end

    if options["itunes_image"]
      entries.each do |entry|
        if entry.data && entry.data[:itunes_image]
          Sidekiq::Client.push(
            'args'  => [entry.public_id, entry.data[:itunes_image]],
            'class' => 'FeedRefresherReceiverImage',
            'queue' => 'feed_refresher_receiver'
          )
        end
      end
    end
  end

end

