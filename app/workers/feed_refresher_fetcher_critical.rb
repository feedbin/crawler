class FeedRefresherFetcherCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher_critical

  def perform(feed_id, feed_url, etag, last_modified, subscribers = nil, body = nil, push_callback = nil, hub_secret = nil)
    f = FeedRefresherFetcher.new
    f.perform(feed_id, feed_url, etag, last_modified, subscribers, body, push_callback, hub_secret)
  end

end