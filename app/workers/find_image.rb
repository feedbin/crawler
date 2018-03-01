class FindImage
  include Sidekiq::Worker
  sidekiq_options queue: :images, retry: false

  def perform(entry_id, feed_id, url, full_url, site_url, content, options = {})
    image = nil

    if options["urls"]
      if attempt = LinkCandidates.new(options["urls"], options["public_id"]).download
        image = attempt
        Librato.increment 'entry_image.create.from_links'
      end
    else
      if attempt = EntryCandidates.new(feed_id, url, full_url, site_url, content, options["public_id"]).find_image
        image = attempt
        Librato.increment 'entry_image.create.from_entry'
      end

      if image.nil?
        if attempt = PageCandidates.new(feed_id, url, full_url, site_url, content, options["public_id"]).find_image
          image = attempt
          Librato.increment 'entry_image.create.from_page'
        end
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
