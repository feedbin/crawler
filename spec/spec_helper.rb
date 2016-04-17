require 'sidekiq'
require 'sidekiq/testing'

$LOAD_PATH.unshift(File.expand_path("../..", __FILE__))
require 'app/boot'

require "webmock/rspec"
require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
