require_relative "test_helper"

class PushedTest < Minitest::Test
  def test_should_get_feed
    pushed = Pushed.new(load_xml, "http://example.com/atom.xml")
    assert_equal 5, pushed.entries.length
    assert_kind_of Feedkit::Parser::XMLEntry, pushed.entries.first
  end
end
