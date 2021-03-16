require_relative "../test_helper"
class UploadImageTest < Minitest::Test
  def setup
    flush
  end

  def test_should_upload
    public_id = SecureRandom.hex
    path = support_file("image.jpeg")
    url = "http://example.com/image.jpg"

    stub_request(:put, /.*\.s3\.amazonaws\.com/)

    assert_equal 0, EntryImage.jobs.size
    UploadImage.new.perform(public_id, "primary", path, url)
    assert_equal 1, EntryImage.jobs.size

    download_cache = DownloadCache.new(url, public_id: public_id, preset_name: "primary")
    assert_equal("https:", download_cache.storage_url)
  end
end
