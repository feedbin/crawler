require_relative "test_helper"

class CacheTest < Minitest::Test
  def test_should_cache_values
    cache_key = "cache_key"
    Cache.write(cache_key, {
      etag: nil,
      last_modified: "last_modified",
    })

    values = Cache.read(cache_key)

    assert_equal("last_modified", values[:last_modified])
    assert_equal(nil, values[:etag])
  end
end
