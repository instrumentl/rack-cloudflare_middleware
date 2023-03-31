# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rack::CloudflareMiddleware::TrustedIps do
  subject(:instance) { described_class.instance }

  before do
    instance.reset!
  end

  describe "#include?" do
    before do
      stub_request(:get, "https://www.cloudflare.com/ips-v4")
        .to_return(status: 200, body: "1.2.3.0/24\n255.255.255.255/32\n\n")
      stub_request(:get, "https://www.cloudflare.com/ips-v6")
        .to_return(status: 200, body: "2001:2003:2003:2004::/64")
      instance.update!
    end

    it do
      expect(instance.include?("1.2.3.1")).to eq true
      expect(instance.include?("1.2.1.1")).to eq false
      expect(instance.include?("2001:2003:2003:2004::1")).to eq true
      expect(instance.include?("::1")).to eq false
    end
  end

  describe "#update!" do
    it "works" do
      s1 = stub_request(:get, "https://www.cloudflare.com/ips-v4")
        .to_return(status: 200, body: "1.2.3.0/24\n255.255.255.255/32\n\n")
      s2 = stub_request(:get, "https://www.cloudflare.com/ips-v6")
        .to_return(status: 200, body: "2001:2003:2003:2004::/64")
      expect(instance.include?("1.2.3.1")).to eq false
      instance.update!
      expect(instance.include?("1.2.3.1")).to eq true
      expect(s1).to have_been_requested
      expect(s2).to have_been_requested
    end

    it "does nothing but warn on error" do
      s1 = stub_request(:get, "https://www.cloudflare.com/ips-v4")
        .to_return(status: 500)
      s2 = stub_request(:get, "https://www.cloudflare.com/ips-v6")
        .to_return(status: 500)
      expect(instance).to receive(:warn).twice
      expect(instance.include?("1.2.3.1")).to eq false
      instance.update!
      expect(instance.include?("1.2.3.1")).to eq false
      expect(s1).to have_been_requested
      expect(s2).to have_been_requested
    end
  end
end
