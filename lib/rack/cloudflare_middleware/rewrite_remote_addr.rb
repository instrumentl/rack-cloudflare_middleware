# frozen_string_literal: true

module Rack
  module CloudflareMiddleware
    class RewriteRemoteAddr
      def initialize(app)
        @app = app
      end

      def call(env)
        TrustedIps.instance.check_update
        if TrustedIps.instance.include? env["REMOTE_ADDR"]
          unless env["HTTP_CF_CONNECTING_IP"].nil?
            env["HTTP_CF_ORIGINAL_REMOTE_ADDR"] = env["REMOTE_ADDR"]
            env["REMOTE_ADDR"] = env["HTTP_CF_CONNECTING_IP"]
          end
        end

        @app.call(env)
      end
    end
  end
end
