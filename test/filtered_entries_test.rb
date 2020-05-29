require_relative "test_helper"

class FilteredEntriesTest < Minitest::Test
  def test_should_get_new_entries
    entries = sample_entries
    results = FormattedEntries.new(entries).new_or_changed
    assert_equal entries.length, results.length
    results.each do |entry|
      assert_nil entry[:update]
    end
  end

  def test_should_get_updated_entries
    entries = sample_entries
    $redis.with do |connection|
      entries.each do |entry|
        connection.set(entry.public_id, 1000)
      end
    end

    results = FormattedEntries.new(entries).new_or_changed
    assert_equal entries.length, results.length
    results.each do |entry|
      assert entry[:update]
    end
  end

  def test_should_ignore_updated_entries
    entries = sample_entries
    $redis.with do |connection|
      entries.each do |entry|
        connection.set(entry.public_id, 1000)
      end
    end

    results = FormattedEntries.new(entries, false).new_or_changed
    assert_equal 0, results.length
  end

  def test_should_ignore_existing_entries
    entries = sample_entries
    $redis.with do |connection|
      entries.each do |entry|
        connection.set(entry.public_id, entry.content.length)
      end
    end

    results = FormattedEntries.new(entries).new_or_changed
    assert_equal 0, results.length
  end

  private

  def sample_entries
    entry = OpenStruct.new(
      public_id: random_string,
      content: random_string,
      to_entry: {data: random_string}
    )
    [entry]
  end
end
