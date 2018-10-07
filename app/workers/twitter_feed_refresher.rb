class TwitterFeedRefresher
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher

  def perform(feed_id, feed_url, keys)
    feed = { id: feed_id }

    parsed_feed = nil

    keys.find do |key|
      options = {
        twitter_screen_name: nil,
        twitter_access_token: key["twitter_access_token"],
        twitter_access_secret: key["twitter_access_secret"]
      }
      begin
        parsed_feed = Feedkit::Feedkit.new().fetch_and_parse(feed_url, options)
      rescue Twitter::Error::Unauthorized
      end
    end

    if parsed_feed.respond_to?(:to_feed)
      entries = parsed_feed.entries
      formatted_entries = FormattedEntries.new(entries)
      if !formatted_entries.new_or_changed.empty?
        feed[:options] = parsed_feed.options
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
    end
  end

end

