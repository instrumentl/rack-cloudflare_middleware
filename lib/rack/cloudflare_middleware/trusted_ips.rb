# frozen_string_literal: true

require "ipaddr"
require "singleton"

require "faraday"

module Rack
  module CloudflareMiddleware
    class TrustedIps
      TIMEOUT = 7.0
      OPEN_TIMEOUT = 4.0

      UPDATE_THRESHOLD = 21600

      attr_reader :ranges
      attr_reader :mtimes

      include Singleton

      def initialize
        reset!
      end

      def reset!
        @ranges = {4 => Set.new, 6 => Set.new}
        @mtimes = {4 => Time.new(1970, 1, 1), 6 => Time.new(1970, 1, 1)}
        load_from_files
      end

      def include?(ip)
        unless ip.is_a? IPAddr
          ip = IPAddr.new(ip)
        end
        if ip.ipv4?
          @ranges[4].any? { _1.include? ip }
        else
          @ranges[6].any? { _1.include? ip }
        end
      end

      def update!
        read_network "https://www.cloudflare.com/ips-v4", 4
        read_network "https://www.cloudflare.com/ips-v6", 6
      end

      def check_update
        if [4, 6].any? { (Time.now - @mtimes[_1]) > UPDATE_THRESHOLD }
          update!
        end
      end

      private

      def load_from_files
        read_file "#{__dir__}/../../../data/ips-v4", 4
        read_file "#{__dir__}/../../../data/ips-v6", 6
      end

      def process_body(body)
        body.lines.map(&:strip).filter { !_1.empty? }.map(&IPAddr.method(:new)).to_set
      end

      def read_file(path, version)
        ::File.open(path) do |f|
          addresses = process_body(f.read)
          @ranges[version] = addresses
          @mtimes[version] = f.mtime
        end
      end

      def read_network(url, version)
        start_request = Time.now
        response = faraday_connection.get(url)
        @ranges[version] = process_body(response.body)
        @mtimes[version] = start_request
      rescue Faraday::Error => e
        warn "Unable to fetch Cloudflare remote IPs: #{e}"
      end

      def faraday_connection
        @faraday_connection ||= Faraday.new do |builder|
          builder.options.open_timeout = OPEN_TIMEOUT
          builder.options.timeout = TIMEOUT
          builder.response :raise_error
        end
      end
    end
  end
end
