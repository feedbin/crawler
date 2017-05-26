class FormattedEntries
  def initialize(entries)
    @entries = entries
  end

  def new_or_changed
    @new_or_changed ||= begin
      @entries.first(300).each_with_object([]) do |entry, array|
        result = nil
        if new?(entry.public_id, entry.public_id_alt)
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
  end

  private

  def new?(public_id, public_id_alt)
    if public_id_alt
      content_lengths[public_id].nil? && content_lengths[public_id_alt].nil?
    else
      content_lengths[public_id].nil?
    end
  end

  def updated?(public_id, content)
    content_length = content_lengths[public_id]
    content_length && content && content.length != content_length
  end

  def content_lengths
    @content_lengths ||= begin
      lengths = {}
      public_ids = @entries.map do |entry|
        [entry.public_id, entry.public_id_alt]
      end.flatten.uniq

      $redis.with do |connection|
        connection.pipelined do
          public_ids.each do |public_id|
            lengths[public_id] = connection.get(public_id)
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