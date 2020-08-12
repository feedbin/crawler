# frozen_string_literal: true

class Cache
  def self.read(*args)
    new.read(*args)
  end

  def self.write(key, **args)
    new.write(key, **args)
  end

  def read(key)
    @read ||= begin
      hash = $redis.with do |redis|
        redis.hgetall key
      end
      hash.transform_keys(&:to_sym)
    end
  end

  def write(key, options: {}, values: {})
    values = values.compact
    unless values.empty?
      $redis.with do |redis|
        redis.mapped_hmset(key, values)
      end
    end
    write_key_expiry(key, options)
  end

  def write_key_expiry(key, options)
    if options[:expires_in]
      $redis.with do |redis|
        redis.expire key, options[:expires_in]
      end
    end
  end
end
