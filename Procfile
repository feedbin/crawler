parallel: bundle exec sidekiq -c 4 -q image_parallel_critical,2 -q image_parallel -q image_parallel_$HOSTNAME -r ./lib/image.rb
serial: bundle exec sidekiq -c 1 -q image_serial_critical_$HOSTNAME,2 -q image_serial_$HOSTNAME -r ./lib/image.rb
downloader: bundle exec sidekiq -c 40 -q feed_downloader_critical,2 -q feed_downloader -r ./lib/refresher.rb
twitter: bundle exec sidekiq -c 15 -q twitter_refresher_critical,2 -q twitter_refresher -r ./lib/refresher.rb
parser: bundle exec sidekiq -c 1 -q feed_parser_critical_$HOSTNAME,2 -q feed_parser_$HOSTNAME -r ./lib/refresher.rb
