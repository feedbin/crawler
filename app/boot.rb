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
require 'app/models/feed_request'
require 'app/models/fetched'
require 'app/models/formatted_entries'
require 'app/models/parsed_entry'
require 'app/models/parsed_feed'
require 'app/models/pub_sub_hubbub'
require 'app/models/pushed'
require 'app/workers/feed_refresher_fetcher'
require 'app/workers/feed_refresher_fetcher_critical'
