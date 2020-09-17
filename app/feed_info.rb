# frozen_string_literal: true

class FeedInfo
  def initialize(feed_id)
    @feed_id = feed_id
  end

  def self.get(feed_id)
    new(feed_id).get
  end

  def get
    puts "--------------------------"
    puts "HTTP Cache: #{HTTPCache.new(@feed_id).cached}"
    puts
    puts "Redirect: #{RedirectCache.read(@feed_id).inspect}"
    puts
    puts "Errors: #{FeedStatus.new(@feed_id).attempt_log}"
    puts "--------------------------"
  end
end
