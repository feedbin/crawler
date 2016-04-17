RSpec.describe FeedRefresherFetcher do
  context 'when the feed exists' do
    it 'scheduled a job for feedbin to process new entries' do
      VCR.use_cassette 'ben ubois' do
        described_class.new.perform(1, 'http://benubois.com/atom.xml')
      end

      refresher_jobs = Sidekiq::Queues.jobs_by_queue['feed_refresher_receiver']
      mark_as_dead_jobs = Sidekiq::Queues.jobs_by_queue['feed_seems_to_be_dead']

      expect(refresher_jobs.count).to eq 1
      expect(mark_as_dead_jobs.count).to eq 0
    end
  end

  context 'when the server responds with an error' do
    it 'scheduled a job for feedbin to mark the feed as dead' do
      VCR.use_cassette '500 error' do
        described_class.new.perform(1, 'http://httpstat.us/500')
      end

      refresher_jobs = Sidekiq::Queues.jobs_by_queue['feed_refresher_receiver']
      mark_as_dead_jobs = Sidekiq::Queues.jobs_by_queue['feed_seems_to_be_dead']

      expect(refresher_jobs.count).to eq 0
      expect(mark_as_dead_jobs.count).to eq 1
    end
  end
  context 'when the server responds with a not found status' do
    it 'scheduled a job for feedbin to mark the feed as dead' do
      VCR.use_cassette '404 not found' do
        described_class.new.perform(1, 'http://httpstat.us/404')
      end

      refresher_jobs = Sidekiq::Queues.jobs_by_queue['feed_refresher_receiver']
      mark_as_dead_jobs = Sidekiq::Queues.jobs_by_queue['feed_seems_to_be_dead']

      expect(refresher_jobs.count).to eq 0
      expect(mark_as_dead_jobs.count).to eq 1
    end
  end
end
