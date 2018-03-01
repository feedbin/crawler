require 'rmagick'

class ProcessedItunesImage

  attr_reader :url, :width, :height

  def initialize(file, public_id)
    @file = file
    @url = nil
    @public_id = public_id
  end

  def process
    success = false
    image = Magick::Image.read(@file).first
    final_image = Pathname.new(File.join(Dir.tmpdir, "#{@public_id}.jpg"))
    image = image.resize_to_fill(200, 200)
    image = image.unsharp_mask(1.5)
    image.write(final_image.to_s)
    @url = upload(final_image)
  ensure
    image && image.destroy!
    final_image && File.exist?(final_image) && File.delete(final_image)
  end

  private

  def upload(file)
    Upload.new(file).upload
  end

end