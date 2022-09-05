source "https://rubygems.org"
git_source(:github) { |name| "https://github.com/#{name}.git" }

gem "down", github: "feedbin/down", branch: "normalize"
gem "unf_ext"

gem "sax-machine", github: "feedbin/sax-machine", branch: "feedbin"
gem "feedjira",    github: "feedbin/feedjira",    branch: "f2"
gem "http",        github: "feedbin/http",        branch: "feedbin"
gem "feedkit",     github: "feedbin/feedkit",     branch: "master"

gem "bundler"
gem "addressable"
gem "connection_pool"
gem "dotenv"
gem "fog-aws"
gem "image_processing"
gem "librato-metrics", "~> 1.6.2"
gem "librato-rack"
gem "mime-types"
gem "nokogiri"
gem "rake"
gem "redis"
gem "resolv"
gem "ruby-vips"
gem "sidekiq"

group :development do
  gem "foreman"
  gem "standard"
end

group :test do
  gem "minitest"
  gem "webmock"
end
