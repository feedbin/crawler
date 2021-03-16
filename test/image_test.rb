require_relative "test_helper"
class ImageTest < Minitest::Test
  def test_should_get_image_size
    file = File.expand_path("support/www/image.jpeg", __dir__)
    image = Image.new(file, target_width: 542, target_height: 304)
    assert_equal(image.width, 640)
    assert_equal(image.height, 828)
    assert_equal(542, image.resized.width)
    assert_equal(701, image.resized.height)
  end

  def test_should_get_face_location
    file = support_file("image.jpeg")
    image = Image.new(file, target_width: 542, target_height: 304)

    assert_equal(455, image.average_face_position("y", File.new(file)))
  end

  def test_should_crop
    file = File.expand_path("support/www/image.jpeg", __dir__)
    image = Image.new(file, target_width: 542, target_height: 304)
    cropped_path = image.smart_crop
    assert cropped_path.include?(".jpg")
    FileUtils.rm cropped_path
  end

  def test_should_return_same_size_image
    file = File.expand_path("support/www/image.jpeg", __dir__)
    image = Image.new(file, target_width: 640, target_height: 828)
    cropped_path = image.smart_crop
    assert cropped_path.include?(".jpg")
  end
end
