# frozen_string_literal: true

class Cache
  def self.read(*args)
    new.read(*args)
  end

  def self.write(*args)
    new.write(*args)
  end

  def read(key)
    @read ||= begin
      hash = $redis.with do |redis|
        redis.hgetall key
      end
      hash.transform_keys(&:to_sym)
    end
  end

  def write(key, values = {})
    values = values.compact
    unless values.empty?
      $redis.with do |redis|
        redis.mapped_hmset(key, values)
      end
    end
  end
end
