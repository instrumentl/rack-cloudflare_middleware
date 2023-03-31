# frozen_string_literal: true

require_relative "cloudflare_middleware/version"
require_relative "cloudflare_middleware/trusted_ips"
require_relative "cloudflare_middleware/remote_addr"
require_relative "cloudflare_middleware/rewrite_remote_addr"
require_relative "cloudflare_middleware/deny_others"

module Rack
  module CloudflareMiddleware
    attr_accessor :logger
  end
end
