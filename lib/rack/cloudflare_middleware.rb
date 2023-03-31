# frozen_string_literal: true

require "ipaddr"

require_relative "cloudflare_middleware/version"
require_relative "cloudflare_middleware/trusted_ips"
require_relative "cloudflare_middleware/rewrite_remote_addr"
require_relative "cloudflare_middleware/deny_others"

module Rack
  module CloudflareMiddleware
    def self.get_remote_addr(env, trust_xff_if_private)
      if trust_xff_if_private && IPAddr.new(env["REMOTE_ADDR"]).private? &&
          !env["HTTP_X_FORWARDED_FOR"].nil? && env["HTTP_X_FORWARDED_FOR"] != ""
        IPAddr.new(env["HTTP_X_FORWARDED_FOR"].split(",")&.last&.strip)
      else
        IPAddr.new(env["REMOTE_ADDR"])
      end
    end
  end
end
