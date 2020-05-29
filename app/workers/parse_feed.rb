# frozen_string_literal: true

class ParseFeed
  include Sidekiq::Worker
  sidekiq_options queue: "feed_parser_#{Socket.gethostname}"

  def perform(feed_id, feed_url, path, file_format)
    feed = parse(path, file_format)
    entries = FilteredEntries.new(feed.entries)
    unless entries.new_or_changed.empty?
      update = {
        feed: feed.to_feed.merge({id: feed_id}),
        entries: formatted_entries.new_or_changed,
      }
      Sidekiq::Client.push(
        'args'  => [update],
        'class' => 'FeedRefresherReceiver',
        'queue' => 'feed_refresher_receiver'
      )
    end
  ensure
    File.delete(path)
  end

  def parse(path, file_format)
    body = File.read(path, binmode: true)
    if file_format == "xml"
      Parser::XMLFeed.new(body, feed_url)
    elsif file_format == "json"
      Parser::JSONFeed.new(body, feed_url)
    end
  end
end
