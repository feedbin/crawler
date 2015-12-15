class FeedRefresherFetcherCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher_critical

  def perform(feed_id, feed_url, options = {})
    f = FeedRefresherFetcher.new
    f.perform(feed_id, feed_url, options = {})
  end

end