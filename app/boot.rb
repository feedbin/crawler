$LOAD_PATH.unshift File.expand_path(File.dirname(File.dirname(__FILE__)))

$stdout.sync = true

require 'bundler/setup'
require 'objspace'
ObjectSpace.trace_object_allocations_start
require 'dotenv'
if ENV["ENV_PATH"]
  Dotenv.load ENV["ENV_PATH"]
else
  Dotenv.load
end

require 'rbtrace'
require 'digest/sha1'
require 'date'
require 'timeout'
require 'net/http'
require 'socket'

require 'sidekiq'
require 'librato-rack'
require 'connection_pool'
require 'redis'
require 'feedkit'

require 'lib/redis'
require 'lib/librato'
require 'lib/worker_stat'
require 'lib/sidekiq'
require 'lib/record_status'

require 'app/models/fetched'
require 'app/models/formatted_entries'
require 'app/models/pub_sub_hubbub'
require 'app/models/pushed'
require 'app/workers/feed_refresher_fetcher'
require 'app/workers/feed_refresher_fetcher_critical'
require 'app/workers/twitter_feed_refresher'
require 'app/workers/twitter_feed_refresher_critical'
