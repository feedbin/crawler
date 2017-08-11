class ItunesImage
  include Sidekiq::Worker
  sidekiq_options queue: :images, retry: false

  def perform(entry_id, image_url)
    image = DownloadImage.new(URI(image_url), false)

    if image.file
      processed_image = ProcessedItunesImage.new(image.file)
      processed_image.process
      puts processed_image.url
    end
  end

end
