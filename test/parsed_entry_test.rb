require_relative 'test_helper'

class ParsedEntryTest < Minitest::Test

  def test_public_id_with_entry_id
    feed_url = 'http://example.com'
    entry = OpenStruct.new(entry_id: 'http://example.com/post')
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal('27aa8c55201e5701e43a333fe70e2e321be4633c', parsed_entry.public_id)
  end

  def test_public_id_without_entry_id
    feed_url = 'http://example.com'
    entry = OpenStruct.new(url: 'http://example.com/post', published: Date.parse("2010-10-31"), title: 'title')
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal('65a8274e8ab7f4ae53a3c4f8c9b82f62315c5623', parsed_entry.public_id)
  end

  def test_public_id_without_entry_id_and_published
    feed_url = 'http://example.com'
    entry = OpenStruct.new(url: 'http://example.com/post', published: nil, title: 'title')
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal('4c47ebc1d14231a8202036886fd4a698a0a0baf8', parsed_entry.public_id)
  end

  def test_public_id_without_entry_id_and_published_and_title
    feed_url = 'http://example.com'
    entry = OpenStruct.new(url: 'http://example.com/post', published: nil, title: nil)
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal('27aa8c55201e5701e43a333fe70e2e321be4633c', parsed_entry.public_id)
  end

  def test_public_id_without_entry_id_and_url
    feed_url = 'http://example.com'
    entry = OpenStruct.new(url: nil, published: Date.parse("2010-10-31"), title: 'title')
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal('afbda42d0aa9e54a7825e3c1dc5240b6a107581d', parsed_entry.public_id)
  end

  def test_alternate_entry_id_http
    feed_url = 'http://example.com'
    entry = OpenStruct.new(entry_id: "64751@https://wordpress.org/plugins/")
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal("64751@http://wordpress.org/plugins/", parsed_entry.entry_id_alt)
  end

  def test_alternate_entry_id_https
    feed_url = 'http://example.com'
    entry = OpenStruct.new(entry_id: "64751@http://wordpress.org/plugins/")
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal("64751@https://wordpress.org/plugins/", parsed_entry.entry_id_alt)
  end

  def test_public_id_alt_with_entry_id_http
    feed_url = 'http://example.com'
    entry = OpenStruct.new(entry_id: 'http://example.com/post')
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal('48097e995f5bb2d9d87a8ae4b3d38744a9f1e1af', parsed_entry.public_id_alt)
    assert_equal('27aa8c55201e5701e43a333fe70e2e321be4633c', parsed_entry.public_id)
  end

  def test_public_id_alt_with_entry_id_https
    feed_url = 'http://example.com'
    entry = OpenStruct.new(entry_id: 'https://example.com/post')
    parsed_entry = ParsedEntry.new(entry, feed_url)
    assert_equal('27aa8c55201e5701e43a333fe70e2e321be4633c', parsed_entry.public_id_alt)
    assert_equal('48097e995f5bb2d9d87a8ae4b3d38744a9f1e1af', parsed_entry.public_id)
  end


end