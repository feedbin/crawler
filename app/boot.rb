$LOAD_PATH.unshift File.expand_path(File.dirname(File.dirname(__FILE__)))

$stdout.sync = true

require "bundler/setup"
require "dotenv"

if ENV["ENV_PATH"]
  Dotenv.load ENV["ENV_PATH"]
else
  Dotenv.load
end

require "digest/sha1"
require "date"
require "socket"

require "sidekiq"
require "librato-rack"
require "connection_pool"
require "redis"
require "feedkit"

require "lib/redis"
require "lib/librato"
require "lib/worker_stat"
require "lib/sidekiq"
require "lib/record_status"
require "lib/cache"

require "app/models/entry_filter"
require "app/workers/feed_parser"
require "app/workers/feed_downloader"
require "app/workers/twitter_refresher"
