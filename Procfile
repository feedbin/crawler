crawler_images_parallel: bundle exec sidekiq --concurrency 4  --queue image_parallel_critical,2         --queue image_parallel         -q image_parallel_$HOSTNAME --require ./lib/image.rb
crawler_images_serial:   bundle exec sidekiq --concurrency 1  --queue image_serial_critical_$HOSTNAME,2 --queue image_serial_$HOSTNAME                             --require ./lib/image.rb
crawler_feeds_parallel:  bundle exec sidekiq --concurrency 40 --queue feed_downloader_critical,2        --queue feed_downloader                                    --require ./lib/refresher.rb
