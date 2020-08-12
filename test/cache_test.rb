require_relative "test_helper"

class CacheTest < Minitest::Test
  def test_should_cache_values
    cache_key = "cache_key"
    Cache.write(cache_key, values: {
      etag: nil,
      last_modified: "last_modified",
    })

    values = Cache.read(cache_key)

    assert_equal("last_modified", values[:last_modified])
    assert_equal(nil, values[:etag])
  end

  def test_should_cache_values_with_exiration
    cache_key = "cache_key"

    Cache.write(cache_key, options: {expires_in: 1}, values: {
      key: "value",
    })

    result = $redis.with do |redis|
      redis.ttl(cache_key)
    end

    assert_equal(1, result)
  end
end
