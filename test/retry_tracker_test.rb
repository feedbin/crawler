require_relative "test_helper"

class RetryTest
  def test_should_be_retrying
    Retry.new(1).retry!
    assert(Retry.new(1).retrying?, "retrying? should be true.")
  end

  def test_should_not_be_retrying
    Retry.new(1).retry!
    Retry.clear!(1)
    assert(!Retry.new(1).retrying?, "retrying? should be false.")
  end
end
