require "rails_helper"

RSpec.describe WebhookEndpoint, type: :model do
  let(:merchant) { create(:user, :business) }

  it "generates a signing secret on create and rotates it" do
    endpoint = described_class.create!(user: merchant, url: "https://merchant.example/hooks")
    original = endpoint.signing_secret

    expect(original).to match(/\Akinko_whsec_[A-Za-z0-9]{40}\z/)
    endpoint.rotate_secret!
    expect(endpoint.reload.signing_secret).not_to eq(original)
  end

  it "allows a single endpoint per merchant" do
    described_class.create!(user: merchant, url: "https://a.example/hooks")

    expect { described_class.create!(user: merchant, url: "https://b.example/hooks") }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe ".safe_url? (SSRF guard)" do
    before { allow(described_class).to receive(:allow_insecure?).and_return(false) }

    def resolve(host, *ips)
      allow(Resolv).to receive(:getaddresses).with(host).and_return(ips)
    end

    it "accepts a public https URL" do
      resolve("merchant.example", "93.184.216.34")
      expect(described_class.safe_url?("https://merchant.example/hooks")).to be(true)
    end

    it "rejects plain http, other schemes and garbage" do
      resolve("merchant.example", "93.184.216.34")

      expect(described_class.safe_url?("http://merchant.example/hooks")).to be(false)
      expect(described_class.safe_url?("ftp://merchant.example/hooks")).to be(false)
      expect(described_class.safe_url?("file:///etc/passwd")).to be(false)
      expect(described_class.safe_url?("not a url")).to be(false)
      expect(described_class.safe_url?(nil)).to be(false)
    end

    it "rejects hosts that resolve to private, loopback, link-local or CGNAT addresses" do
      {
        "loopback.example" => "127.0.0.1",
        "private10.example" => "10.0.0.5",
        "private172.example" => "172.16.3.4",
        "private192.example" => "192.168.1.1",
        "metadata.example" => "169.254.169.254",
        "cgnat.example" => "100.64.0.1",
        "zero.example" => "0.0.0.0",
        "v6loop.example" => "::1",
        "v6ula.example" => "fd00::1",
        "v6link.example" => "fe80::1"
      }.each do |host, ip|
        resolve(host, ip)
        expect(described_class.safe_url?("https://#{host}/hooks")).to be(false), "accepted #{host} -> #{ip}"
      end
    end

    it "rejects a host when any of its addresses is private (DNS round-robin trick)" do
      resolve("mixed.example", "93.184.216.34", "10.0.0.1")
      expect(described_class.safe_url?("https://mixed.example/hooks")).to be(false)
    end

    it "rejects a host that does not resolve" do
      resolve("nxdomain.example")
      expect(described_class.safe_url?("https://nxdomain.example/hooks")).to be(false)
    end

    it "is enforced as a validation" do
      resolve("internal.example", "10.1.2.3")
      endpoint = described_class.new(user: merchant, url: "https://internal.example/hooks")

      expect(endpoint).not_to be_valid
      expect(endpoint.errors[:url]).to include("must be a public https URL")
    end
  end
end
