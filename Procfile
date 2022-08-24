parallel: bundle exec sidekiq -c 4 -q image_parallel_critical,2 -q image_parallel -q image_parallel_$HOSTNAME -r ./lib/image.rb
serial: bundle exec sidekiq -c 1 -q image_serial_critical_$HOSTNAME,2 -q image_serial_$HOSTNAME -r ./lib/image.rb
