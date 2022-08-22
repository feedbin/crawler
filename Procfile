downloader: bundle exec sidekiq -c 40 -q feed_downloader_critical,2 -q feed_downloader -r ./lib/crawler.rb
twitter: bundle exec sidekiq -c 15 -q twitter_refresher_critical,2 -q twitter_refresher -r ./lib/crawler.rb
parser: bundle exec sidekiq -c 1 -q feed_parser_critical_$HOSTNAME,2 -q feed_parser_$HOSTNAME -r ./lib/crawler.rb