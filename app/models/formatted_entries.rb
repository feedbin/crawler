class FormattedEntries
  def initialize(entries)
    @entries = entries
    set_ids
  end

  def entries
    @entries.first(300).each_with_object([]) do |entry, array|
      result = nil
      if new?(entry.public_id)
        result = entry.to_entry
      elsif updated?(entry.public_id, entry.content)
        result = entry.to_entry
        result[:update] = true
      end
      if result
        array.push(result)
      end
    end
  end

  private

  def set_ids
    @set_ids ||= begin
      $redis.with do |connection|
        connection.pipelined do
          @entries.each do |entry|
            content_length = (entry.content) ? entry.content.length : 1
            connection.set(entry.public_id, content_length)
          end
        end
      end
    end
  end

  def new?(public_id)
    content_lengths[public_id].nil?
  end

  def updated?(public_id, content)
    content_length = content_lengths[public_id]
    content_length && content && content.length != content_length
  end

  def content_lengths
    @content_lengths ||= begin
      lengths = {}
      public_ids = @entries.map { |entry| entry.public_id }

      Sidekiq.redis do |conn|
        conn.pipelined do
          public_ids.each do |public_id|
            lengths[public_id] = conn.hget("entry:public_ids:#{public_id[0..4]}", public_id)
          end
        end
      end

      lengths.each do |public_id, future|
        value = future.value.to_i
        if value == 0
          content_length = nil
        elsif value == 1
          content_length = false
        else
          content_length = value
        end
        lengths[public_id] = content_length
      end

      lengths
    end
  end


end