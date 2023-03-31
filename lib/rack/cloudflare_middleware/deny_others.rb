# frozen_string_literal: true

module Rack
  module CloudflareMiddleware
    class DenyOthers
      def initialize(app, allow_private: false, on_fail_proc: nil)
        @allow_private = allow_private
        @app = app
        @on_fail_proc = on_fail_proc
      end

      def call(env)
        TrustedIps.instance.check_update
        remote_addr = IPAddr.new env["REMOTE_ADDR"]
        if (@allow_private && (remote_addr.private? || remote_addr.loopback?)) || TrustedIps.instance.include?(remote_addr)
          @app.call(env)
        elsif @on_fail_proc.nil?
          default_on_fail(remote_addr)
        else
          @on_fail_proc.call(env)
        end
      end

      private

      def default_on_fail(remote_addr)
        ["403", {"Content-Type" => "text/plain"}, ["Forbidden by policy statement (#{remote_addr})"]]
      end
    end
  end
end
