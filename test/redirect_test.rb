require_relative "test_helper"
class RedirectTest < Minitest::Test
  def test_should_have_cache_key
    redirect = Redirect.new(1, status: 301, from: "http://example.com", to: "http://example.com/final")
    assert_equal("3981c0f11e525f3f0f4498a238f448957ff1929c", redirect.cache_key)
  end
end
