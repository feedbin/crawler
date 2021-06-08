require_relative "test_helper"

class ThrottleTest < Minitest::Test

  def setup
    flush
  end

  def test_throttled
    ENV["THROTTLED_HOSTS"] = "example.com"
    assert     Throttle.throttled?("https://www.example.com", Time.now.to_i)
    assert_equal(false, Throttle.throttled?("https://www.example.com", Time.now.to_i - Throttle::TIMEOUT))
    assert_equal(false, Throttle.throttled?("https://www.example.com", nil))
    assert_equal(false, Throttle.throttled?("https://www.not-example.com", Time.now.to_i))
    assert_equal(false, Throttle.throttled?(nil, nil))
  end
end
