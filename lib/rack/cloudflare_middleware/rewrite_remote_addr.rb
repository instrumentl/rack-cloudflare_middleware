# frozen_string_literal: true

module Rack
  module CloudflareMiddleware
    class RewriteRemoteAddr
      def initialize(app, trust_xff_if_private: false)
        @trust_xff_if_private = trust_xff_if_private
        @app = app
      end

      def call(env)
        TrustedIps.instance.check_update
        remote_addr = Rack::CloudflareMiddleware.get_remote_addr(env, @trust_xff_if_private)
        if TrustedIps.instance.include? remote_addr
          unless env["HTTP_CF_CONNECTING_IP"].nil?
            env["HTTP_CF_ORIGINAL_REMOTE_ADDR"] = remote_addr
            env["REMOTE_ADDR"] = env["HTTP_CF_CONNECTING_IP"]
          end
        end

        @app.call(env)
      end
    end
  end
end
