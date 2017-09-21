$LOAD_PATH.unshift File.expand_path(File.dirname(File.dirname(__FILE__)))

$stdout.sync = true

OPENCV_CLASSIFIER = File.absolute_path("lib/opencv/haarcascade_frontalface_alt.xml")

require 'bundler/setup'
require 'dotenv'
Dotenv.load

require 'socket'
require 'etc'
require 'net/http'
require 'securerandom'
require 'time'
require 'uri'

require 'addressable'
require 'dotenv'
require 'fog/aws'
require 'httparty'
require 'http'
require 'librato-rack'
require 'mime-types'
require 'nokogumbo'
require 'redis'
require 'rmagick'
require 'opencv'
require 'sidekiq'

require 'lib/redis'
require 'lib/librato'
require 'lib/worker_stat'
require 'lib/sidekiq'

require 'app/models/candidates'
require 'app/models/download_image'
require 'app/models/entry_candidates'
require 'app/models/image_candidate'
require 'app/models/page_candidates'
require 'app/models/processed_image'
require 'app/models/processed_itunes_image'
require 'app/models/upload'
require 'app/workers/find_image'
require 'app/workers/itunes_image'
require 'app/workers/find_image_critical'
