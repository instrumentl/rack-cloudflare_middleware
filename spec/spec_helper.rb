require "rspec"
require "rspec/its"
require "webmock/rspec"
require "rack/cloudflare_middleware"
require "rack/test"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include Rack::Test::Methods

  WebMock.disable_net_connect!(
    allow_localhost: true
  )
end
