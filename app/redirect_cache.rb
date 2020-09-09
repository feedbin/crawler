# frozen_string_literal: true

class RedirectCache

  # 4 redirect/hr 24hrs a day for 7 days
  PERSIST_AFTER = 4 * 24 * 7

  attr_reader :redirects

  def initialize(redirects: nil, feed_url: nil)
    @redirects = redirects
    @feed_url = feed_url
  end

  def self.save(redirects, feed_url:)
    new(redirects: redirects, feed_url: feed_url).save
  end

  def self.read(feed_url)
    new(feed_url: feed_url).read
  end

  def self.delete(feed_url)
    new(feed_url: feed_url).delete
  end

  def save
    Cache.write(stable_key, {to: @redirects.last.to}) if redirect_stable?
  end

  def redirect_stable?
    return false if redirects.empty?
    return false unless redirects.all?(&:permanent?)
    Cache.increment(counter_key, options: {expires_in: 72 * 60 * 60}) > PERSIST_AFTER
  end

  def read
    Cache.read(stable_key)[:to]
  end

  def delete
    Cache.delete(stable_key)
  end

  def counter_key
    @counter_key ||= begin
      "refresher_redirect_tmp_" + Digest::SHA1.hexdigest(@redirects.map(&:cache_key).join)
    end
  end

  def stable_key
    @stable_key ||= begin
      "refresher_redirect_stable_" + Digest::SHA1.hexdigest(@feed_url)
    end
  end
end

class Redirect
  PERMANENT_REDIRECTS = [301, 308].to_set.freeze

  attr_reader :from, :to

  def initialize(feed_id, status:, from:, to:)
    @feed_id = feed_id
    @status = status
    @from = from
    @to = to
  end

  def permanent?
    PERMANENT_REDIRECTS.include?(@status)
  end

  def cache_key
    @cache_key ||= Digest::SHA1.hexdigest([@feed_id, @status, @from, @to].join)
  end
end



