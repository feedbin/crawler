$LOAD_PATH.unshift File.expand_path(File.dirname(File.dirname(__FILE__)))

$stdout.sync = true

require 'bundler/setup'
require 'dotenv'
Dotenv.load

require 'digest/sha1'
require 'date'
require 'timeout'
require 'net/http'
require 'socket'

require 'sidekiq'
require 'feedjira'

require 'lib/core_ext/blank'
require 'lib/core_ext/try'
require 'lib/feedjira_extension'
require 'lib/sidekiq'
require 'app/models/feed_fetcher'
require 'app/workers/feed_refresher_fetcher'
require 'app/workers/feed_refresher_fetcher_critical'
