# frozen_string_literal: true

require "spec_helper"

require "rack/builder"

class OkApplication
  def call(env)
    ["200", {"Content-Type" => "text/plain"}, ["OK"]]
  end
end

RSpec.describe Rack::CloudflareMiddleware::DenyOthers do
  let(:tips) { Rack::CloudflareMiddleware::TrustedIps.instance }

  before do
    tips.reset!
    stub_request(:get, "https://www.cloudflare.com/ips-v4")
      .to_return(status: 200, body: "1.2.3.0/24\n255.255.255.255/32\n\n")
    stub_request(:get, "https://www.cloudflare.com/ips-v6")
      .to_return(status: 200, body: "2001:2003:2003:2004::/64")
    tips.update!
  end

  let(:app) do
    kwargs = {allow_private: allow_private}
    Rack::Builder.new do
      use Rack::CloudflareMiddleware::DenyOthers, **kwargs
      run OkApplication.new
    end
  end

  context "allow_private = true" do
    let(:allow_private) { true }

    it "allows private connections" do
      get "/", nil, {"REMOTE_ADDR" => "127.0.0.1"}
      expect(last_response).to be_successful
    end

    it "allows trusted connections" do
      get "/", nil, {"REMOTE_ADDR" => "1.2.3.1"}
      expect(last_response).to be_successful
    end

    it "blocks untrusted connections" do
      get "/", nil, {"REMOTE_ADDR" => "9.9.9.9"}
      expect(last_response.status).to eq 403
    end
  end

  context "allow_private = false" do
    let(:allow_private) { false }

    it "blocks private connections" do
      get "/", nil, {"REMOTE_ADDR" => "127.0.0.1"}
      expect(last_response.status).to eq 403
    end

    it "allows trusted connections" do
      get "/", nil, {"REMOTE_ADDR" => "1.2.3.1"}
      expect(last_response).to be_successful
    end

    it "blocks untrusted connections" do
      get "/", nil, {"REMOTE_ADDR" => "9.9.9.9"}
      expect(last_response.status).to eq 403
    end
  end
end
