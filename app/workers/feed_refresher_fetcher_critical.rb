class FeedRefresherFetcherCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher_critical
  def perform(*args)
    FeedRefresherFetcher.new.perform(*args)
  end
end
