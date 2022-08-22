source "https://rubygems.org"
git_source(:github) { |name| "https://github.com/#{name}.git" }

gem "down", github: "feedbin/down", branch: "normalize"

gem "bundler"
gem "resolv"
gem "rake"
gem "addressable"
gem "dotenv"
gem "fog-aws"
gem "http"
gem "image_processing"
gem "librato-metrics", "= 1.6.1"
gem "librato-rack"
gem "mime-types"
gem "redis"
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
