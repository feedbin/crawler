# frozen_string_literal: true

class FeedParser
  include Sidekiq::Worker
  sidekiq_options queue: "feed_parser_#{Socket.gethostname}", retry: false

  def perform(feed_id, feed_url, path, file_format)
    @feed_id = feed_id
    @feed_url = feed_url
    @path = path
    @file_format = file_format

    entries = EntryFilter.filter!(parsed_feed.entries)
    save(parsed_feed.to_feed, entries) unless entries.empty?
  ensure
    File.delete(path)
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
      Feedkit::Parser.parse!(@file_format, body, @feed_url)
    end
  end
end
