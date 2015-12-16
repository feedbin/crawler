class Pushed

  def initialize(xml, feed_url)
    @xml = xml
    @feed_url = feed_url
  end

  def feed
    @feed ||= Feedjira::Feed.parse(@xml)
  end

  def entries
    @entries ||= begin
      entries = []
      if feed.entries.respond_to?(:any?) && feed.entries.any?
        entries = feed.entries.map do |entry|
          ParsedEntry.new(entry, @feed_url)
        end
        entries = entries.uniq { |entry| entry.public_id }
      end
      entries
    end
  end

end