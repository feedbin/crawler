# frozen_string_literal: true

class FeedParser
  include Sidekiq::Worker
  sidekiq_options queue: "feed_parser_#{Socket.gethostname}", retry: false

  def perform(feed_id, feed_url, path, encoding = nil)
    @feed_id = feed_id
    @feed_url = feed_url
    @path = path
    @encoding = encoding

    entries = EntryFilter.filter!(parsed_feed.entries)
    save(parsed_feed.to_feed, entries) unless entries.empty?
    FeedStatus.clear!(@feed_id)
    counts(parsed_feed.entries, entries)
  rescue Feedkit::NotFeed => exception
    Sidekiq.logger.info "Feedkit::NotFeed: id=#{@feed_id} url=#{@feed_url}"
    FeedStatus.new(@feed_id).error!(exception)
  ensure
    cleanup
  end

  def save(feed, entries)
    Sidekiq::Client.push(
      "class" => "FeedRefresherReceiver",
      "queue" => "feed_refresher_receiver",
      "args" => [{
        "feed" => feed.merge({"id" => @feed_id}),
        "entries" => entries
      }]
    )
  end

  def parsed_feed
    @parsed_feed ||= begin
      body = File.read(@path, binmode: true)
      Feedkit::Parser.parse!(body, url: @feed_url, encoding: @encoding)
    end
  end

  def counts(all_entries, new_entries)
    all_entries_count = all_entries.count
    new_entries_count = new_entries.count

    return if all_entries_count == 0 || new_entries_count == 0

    new_entries_count = new_entries.reject {|entry| entry[:update] == true }.count

    if new_entries_count == all_entries_count
      Sidekiq.logger.info("All new: id=#{@feed_id} url=#{@feed_url} all=#{all_entries_count} new=#{new_entries_count}")
    end
  end

  def cleanup
    File.unlink(@path) rescue Errno::ENOENT
  end
end

class FeedParserCritical
  include Sidekiq::Worker
  sidekiq_options queue: "feed_parser_critical_#{Socket.gethostname}", retry: false
  def perform(*args)
    FeedParser.new.perform(*args)
  end
end

