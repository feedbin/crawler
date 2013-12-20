$LOAD_PATH.unshift File.expand_path(File.dirname(File.dirname(__FILE__)))

$stdout.sync = true

require 'bundler/setup'
require 'dotenv'
Dotenv.load

require 'digest/sha1'
require 'date'
require 'timeout'
require 'net/http'

require 'sidekiq'
require 'feedzirra'
require 'librato/metrics'

require 'lib/core_ext/blank'
require 'lib/core_ext/try'
require 'lib/feedzirra_extension'
require 'lib/sidekiq'
require 'app/models/feed_fetcher'
require 'app/workers/feed_refresher_fetcher'
require 'app/workers/feed_refresher_fetcher_critical'

if ENV['LIBRATO_USER'] && ENV['LIBRATO_TOKEN']
  Librato::Metrics.authenticate ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN']
  $librato_queue = Librato::Metrics::Queue.new(autosubmit_interval: 60)
end