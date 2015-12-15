class FeedRefresherFetcher
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher

  # Options: etag, last_modified, subscriptions_count, xml, push_callback, hub_secret
  def perform(feed_id, feed_url, options = {})
    feed = { id: feed_id }
    if options["xml"]
      entries = Pushed.new(options["xml"], feed_url).entries
    else
      fetched = Fetched.new(feed_id, feed_url, options)
      entries = fetched.entries
      feed = feed.merge(fetched.feed)
      if fetched.parsed_feed && options["push_callback"] && options["hub_secret"]
        push_subscribe(fetched.parsed_feed, options)
      end
    end

    entries = FormattedEntries.new(entries)
    if entries.entries.any?
      update = {
        feed: feed,
        entries: entries.entries,
      }
      Sidekiq::Client.push(
        'args'  => [update],
        'class' => 'FeedRefresherReceiver',
        'queue' => 'feed_refresher_receiver'
      )
    end
  end

  def push_subscribe(feed, opts)
    PubSubHubbub.new(
      feed.hubs,
      feed.self_url,
      opts["push_callback"],
      opts["hub_secret"],
      opts["subscriptions_count"]
    ).subscribe
  rescue Exception => e
    puts "PuSH Exception #{e.inspect}: #{e.backtrace.inspect}"
  end

end

