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
require "connection_pool"
require "redis"
require "feedkit"

require "app/redis"
require "app/cache"
require "app/feed_status"
require "app/redirect_cache"
require "app/http_cache"
require "app/entry_filter"

require "app/jobs/feed_parser"
require "app/jobs/feed_downloader"
require "app/jobs/twitter_refresher"
