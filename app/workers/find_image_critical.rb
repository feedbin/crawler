class FindImageCritical
  include Sidekiq::Worker
  sidekiq_options queue: :images_critical

  def perform(*args)
    FindImage.new().perform(*args)
  end
end
