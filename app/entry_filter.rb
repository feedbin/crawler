# frozen_string_literal: true

class EntryFilter

  def self.filter!(*args, **kwargs)
    new(*args, **kwargs).filter
  end

  def initialize(entries, check_for_updates: true)
    @entries = entries
    @check_for_updates = check_for_updates
  end

  def filter
    @filter ||= begin
      @entries.first(300).each_with_object([]) do |entry, array|
        if new?(entry.public_id)
          array.push(entry.to_entry)
        elsif @check_for_updates && updated?(entry.public_id, entry.content)
          result = entry.to_entry
          result[:update] = true
          array.push(result)
        end
      end
    end
  end

  private

  def new?(public_id)
    saved_entries[public_id] == 0
  end

  def updated?(public_id, content)
    length = saved_entries[public_id]
    return false if !length
    return false if !content
    return false if length == 1
    content.length != length
  end

  def saved_entries
    @saved_entries ||= $redis.with do |redis|
      keys = @entries.map(&:public_id)
      redis.mapped_mget(*keys).transform_values(&:to_i)
    end
  end
end
