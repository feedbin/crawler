require "bundler/setup"
require_relative "../app/boot"


FeedRefresherFetcher.new.perform(1, "https://feedbin.com/blog/atom.xml", nil, nil, 10)
