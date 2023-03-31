# frozen_string_literal: true

require "spec_helper"

class EchoApplication
  def call(env)
    ["200", {"Content-Type" => "application/json"}, [
      JSON.generate(env.slice("REMOTE_ADDR", "HTTP_CF_CONNECTING_IP", "HTTP_CF_ORIGINAL_REMOTE_ADDR"))
    ]]
  end
end

RSpec.describe Rack::CloudflareMiddleware::RewriteRemoteAddr do
  let(:tips) { Rack::CloudflareMiddleware::TrustedIps.instance }
  let(:middleware_kwargs) { {} }

  before do
    tips.reset!
    stub_request(:get, "https://www.cloudflare.com/ips-v4")
      .to_return(status: 200, body: "1.2.3.0/24\n255.255.255.255/32\n\n")
    stub_request(:get, "https://www.cloudflare.com/ips-v6")
      .to_return(status: 200, body: "2001:2003:2003:2004::/64")
    tips.update!
  end

  let(:app) do
    described_class.new(EchoApplication.new, **middleware_kwargs)
  end

  let(:parsed) { JSON.parse(last_response.body) }

  it "does nothing if no CF-Connecting-IP" do
    get "/", nil, {"REMOTE_ADDR" => "127.0.0.2"}
    expect(last_response).to be_successful
    expect(parsed).to eq({"REMOTE_ADDR" => "127.0.0.2"})
  end

  it "does nothing if REMOTE_ADDR not trusted" do
    get "/", nil, {"REMOTE_ADDR" => "127.0.0.2", "HTTP_CF_CONNECTING_IP" => "8.8.8.8"}
    expect(last_response).to be_successful
    expect(parsed).to eq({"REMOTE_ADDR" => "127.0.0.2", "HTTP_CF_CONNECTING_IP" => "8.8.8.8"})
  end

  it "copies in CF-Connecting-IP if trusted" do
    get "/", nil, {"REMOTE_ADDR" => "1.2.3.1", "HTTP_CF_CONNECTING_IP" => "8.8.8.8"}
    expect(last_response).to be_successful
    expect(parsed).to eq({
      "REMOTE_ADDR" => "8.8.8.8",
      "HTTP_CF_CONNECTING_IP" => "8.8.8.8",
      "HTTP_CF_ORIGINAL_REMOTE_ADDR" => "1.2.3.1"
    })
  end

  context "trust_xff_if_private = true" do
    let(:middleware_kwargs) { {trust_xff_if_private: true} }

    it "does nothing if xff is absent" do
      get "/", nil, {"REMOTE_ADDR" => "10.1.1.1"}
      expect(parsed).to eq({"REMOTE_ADDR" => "10.1.1.1"})
    end

    it "does nothing if invalid XFF" do
      get "/", nil, {"REMOTE_ADDR" => "10.1.1.1", "HTTP_X_FORWARDED_FOR" => "8.8.8.8"}
      expect(parsed).to eq({"REMOTE_ADDR" => "10.1.1.1"})
    end

    it "rewrites REMOTE_ADDR if valid XFF" do
      get "/", nil, {"REMOTE_ADDR" => "10.1.1.1", "HTTP_X_FORWARDED_FOR" => "8.8.8.8,1.2.3.4", "HTTP_CF_CONNECTING_IP" => "8.8.8.8"}
      expect(parsed).to eq({"HTTP_CF_CONNECTING_IP" => "8.8.8.8", "HTTP_CF_ORIGINAL_REMOTE_ADDR" => "1.2.3.4", "REMOTE_ADDR" => "8.8.8.8"})
    end
  end
end
