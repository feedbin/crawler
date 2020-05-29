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
require "lib/http_cache"

require "app/models/filtered_entries"
require "app/models/pub_sub_hubbub"
require "app/models/pushed"

require "app/workers/feed_parser"
require "app/workers/feed_downloader"
require "app/workers/twitter_refresher"
