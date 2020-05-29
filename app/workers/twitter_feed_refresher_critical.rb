class TwitterFeedRefresherCritical
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_fetcher_critical
  def perform(*args)
    TwitterFeedRefresher.new.perform(*args)
  end
end
