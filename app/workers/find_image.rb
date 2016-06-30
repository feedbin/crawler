class FindImage
  include Sidekiq::Worker
  sidekiq_options queue: :images, retry: false

  def perform(entry_id, feed_id, url, full_url, site_url, content)
    image = nil
    if attempt = EntryCandidates.new(feed_id, url, full_url, site_url, content).find_image
      image = attempt
      Librato.increment 'entry_image.create.from_entry'
    end
    if image.nil?
      if attempt = PageCandidates.new(feed_id, url, full_url, site_url, content).find_image
        image = attempt
        Librato.increment 'entry_image.create.from_page'
      end
    end

    if !image.nil?
      Sidekiq::Client.push(
        'args'  => [entry_id, image],
        'class' => 'EntryImage',
        'queue' => 'default'
      )
    end
  end
end
