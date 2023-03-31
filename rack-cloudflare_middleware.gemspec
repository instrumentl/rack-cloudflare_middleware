# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rack/cloudflare_middleware/version"

Gem::Specification.new do |spec|
  spec.name = "rack-cloudflare_middleware"
  spec.version = Rack::CloudflareMiddleware::VERSION
  spec.authors = ["James Brown"]
  spec.email = ["james@instrumentl.com"]
  spec.license = "ISC"

  spec.summary = "Rack middleware for handling Cloudflare remote IP headers"
  spec.homepage = "https://github.com/instrumentl/rack-cloudflare_middleware"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 1.0", "< 3"
  spec.add_dependency "rack", ">= 2", "< 4"

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1"
end
