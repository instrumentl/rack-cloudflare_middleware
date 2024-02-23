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
    stub_request(:get, "https://www.cloudflare.com/ips-v4/")
      .to_return(status: 200, body: "1.2.3.0/24\n255.255.255.255/32\n\n")
    stub_request(:get, "https://www.cloudflare.com/ips-v6/")
      .to_return(status: 200, body: "2001:2003:2003:2004::/64")
    tips.update!
  end

  let(:middleware_kwargs) { {allow_private: allow_private} }

  let(:app) do
    kwargs = middleware_kwargs
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

    it "allows trusted IPv6 connections" do
      get "/", nil, {"REMOTE_ADDR" => "2001:2003:2003:2004::10"}
      expect(last_response).to be_successful
    end

    it "blocks untrusted connections" do
      get "/", nil, {"REMOTE_ADDR" => "9.9.9.9"}
      expect(last_response.status).to eq 403
      expect(last_response.body).to eq "Forbidden by policy statement (9.9.9.9)"
    end
  end

  context "on_fail_proc provided" do
    let(:middleware_kwargs) { {allow_private: false, on_fail_proc: ->(env) { [600, {"Content-Type" => "text/plain"}, [env["HTTP_X_FOOBAR"]]] }} }

    it "calls on_fail_proc" do
      get "/", nil, {"REMOTE_ADDR" => "127.0.0.1", "HTTP_X_FOOBAR" => "baz"}
      expect(last_response.status).to eq 600
      expect(last_response.body).to eq "baz"
    end
  end

  context "trusted_request_proc provided" do
    let(:middleware_kwargs) { {allow_private: false, trusted_request_proc: ->(request) { request.path.start_with? "/health" }} }

    it "allows requests to /health/foo" do
      get "/health/foo", nil, {"REMOTE_ADDR" => "127.0.0.1"}
      expect(last_response.status).to eq 200
    end

    it "still disallows other requests" do
      get "/evil/baz", nil, {"REMOTE_ADDR" => "127.0.0.1"}
      expect(last_response.status).to eq 403
    end
  end

  context "trust_xff_if_private = true" do
    let(:middleware_kwargs) { {trust_xff_if_private: true, allow_private: false} }

    it "blocks requests with no xff" do
      get "/", nil, {"REMOTE_ADDR" => "10.1.1.1"}
      expect(last_response.status).to eq 403
    end

    it "blocks requests with invalid XFF" do
      get "/", nil, {"REMOTE_ADDR" => "10.1.1.1", "HTTP_X_FORWARDED_FOR" => "8.8.8.8"}
      expect(last_response.status).to eq 403
    end

    it "allows requests with a valid last XFF and private remote addr" do
      get "/", nil, {"REMOTE_ADDR" => "10.1.1.1", "HTTP_X_FORWARDED_FOR" => "8.8.8.8,1.2.3.4"}
      expect(last_response.status).to eq 200
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

    it "allows trusted IPv6 connections" do
      get "/", nil, {"REMOTE_ADDR" => "2001:2003:2003:2004::10"}
      expect(last_response).to be_successful
    end

    it "blocks untrusted connections" do
      get "/", nil, {"REMOTE_ADDR" => "9.9.9.9"}
      expect(last_response.status).to eq 403
    end
  end
end
