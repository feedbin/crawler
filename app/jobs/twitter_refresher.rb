# frozen_string_literal: true

class TwitterRefresher
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader, retry: false

  def perform(feed_id, feed_url, keys)
    tweets = nil

    recognized_url = Feedkit::TwitterURLRecognizer.new(feed_url, nil)

    if recognized_url.valid?
      keys.find do |key|
        tweets = Feedkit::Tweets.new(feed_url, key["twitter_access_token"], key["twitter_access_secret"])
      rescue Twitter::Error::Unauthorized
      end
    end

    if tweets&.feed&.respond_to?(:to_feed)
      entries = EntryFilter.filter!(tweets.feed.entries, check_for_updates: false)
      unless entries.empty?
        Sidekiq::Client.push(
          "class" => "FeedRefresherReceiver",
          "queue" => "feed_refresher_receiver",
          "args" => [{
            feed: {
              id: feed_id,
              options: parsed_feed.options
            },
            entries: entries
          }],
        )
      end
    end
  end
end

class TwitterRefresherCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_downloader_critical, retry: false
  def perform(*args)
    TwitterRefresher.new.perform(*args)
  end
end
