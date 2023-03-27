# frozen_string_literal: true

module Rack
  module CloudflareMiddleware
    class DenyOthers
      def initialize(app, allow_private: false)
        @allow_private = allow_private
        @app = app
      end

      def call(env)
        TrustedIps.instance.check_update
        remote_addr = IPAddr.new env["REMOTE_ADDR"]
        if (@allow_private && (remote_addr.private? || remote_addr.loopback?)) || TrustedIps.instance.include?(remote_addr)
          @app.call(env)
        else
          ["403", {"Content-Type" => "text/plain"}, ["Forbidden by policy statement"]]
        end
      end
    end
  end
end
