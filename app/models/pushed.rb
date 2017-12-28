class Pushed

  def initialize(xml, feed_url)
    @xml = xml
    @feed_url = feed_url
  end

  def feed
    @feed ||= begin
      parser = Feedjira.parser_for_xml(@xml)
      parser.parse(@xml)
    end
  end

  def entries
    @entries ||= begin
      entries = []
      if feed.entries.respond_to?(:any?) && feed.entries.any?
        entries = feed.entries.map do |entry|
          Feedkit::Parser::XMLEntry.new(entry, @feed_url)
        end
        entries = entries.uniq { |entry| entry.public_id }
      end
      entries
    end
  end

end