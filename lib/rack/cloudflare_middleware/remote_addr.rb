# frozen_string_literal: true

require "ipaddr"

module Rack
  module CloudflareMiddleware
    module RemoteAddr
      def self.get_remote_addr(env, trust_xff_if_private)
        if trust_xff_if_private && IPAddr.new(env["REMOTE_ADDR"]).private?
          if !env["HTTP_X_FORWARDED_FOR"].nil? && env["HTTP_X_FORWARDED_FOR"] != ""
            return IPAddr.new(env["HTTP_X_FORWARDED_FOR"].split(",")&.last&.strip)
          end
        end
        IPAddr.new(env["REMOTE_ADDR"])
      end
    end
  end
end
