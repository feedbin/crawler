downloader: bundle exec sidekiq -c 40 -q feed_downloader_critical,2 -q feed_downloader -r ./app/boot.rb
twitter: bundle exec sidekiq -c 15 -q twitter_refresher_critical,2 -q twitter_refresher -r ./app/boot.rb
parser: bundle exec sidekiq -c 1 -q feed_parser_critical_$HOSTNAME,2 -q feed_parser_$HOSTNAME -r ./app/boot.rb