require "rails_helper"

RSpec.describe Webhooks::Signature do
  let(:secret) { "kinko_whsec_test" }
  let(:body) { { id: "evt_1", type: "payment_request.paid" }.to_json }
  let(:now) { 1_800_000_000 }

  it "builds a t=…,v1=… header with an HMAC-SHA256 over '<t>.<body>'" do
    header = described_class.header(body, secret, timestamp: now)
    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{now}.#{body}")

    expect(header).to eq("t=#{now},v1=#{expected}")
  end

  it "verifies a header it produced" do
    header = described_class.header(body, secret, timestamp: now)
    expect(described_class.valid?(body, header, secret, now: now + 10)).to be(true)
  end

  it "rejects a tampered body, a wrong secret and a malformed header" do
    header = described_class.header(body, secret, timestamp: now)

    expect(described_class.valid?(body.sub("paid", "canceled"), header, secret, now: now)).to be(false)
    expect(described_class.valid?(body, header, "other", now: now)).to be(false)
    expect(described_class.valid?(body, "garbage", secret, now: now)).to be(false)
    expect(described_class.valid?(body, nil, secret, now: now)).to be(false)
  end

  it "rejects timestamps outside the 5 minute tolerance (replay protection)" do
    header = described_class.header(body, secret, timestamp: now)

    expect(described_class.valid?(body, header, secret, now: now + 301)).to be(false)
    expect(described_class.valid?(body, header, secret, now: now - 301)).to be(false)
  end
end
