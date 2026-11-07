require "rails_helper"

RSpec.describe MerchantApiKey, type: :model do
  let(:merchant) { create(:user, :business) }

  describe ".issue!" do
    it "returns the plain key once and stores only its SHA-256 digest" do
      key = described_class.issue!(user: merchant, name: "Production")

      expect(key.plain_token).to match(/\Akinko_sk_[A-Za-z0-9]{40}\z/)
      expect(key.token_digest).to eq(OpenSSL::Digest::SHA256.hexdigest(key.plain_token))
      expect(key.last4).to eq(key.plain_token[-4..])
      expect(described_class.find(key.id).plain_token).to be_nil
      expect(described_class.find(key.id).attributes.values).not_to include(key.plain_token)
    end

    it "only issues keys to business users" do
      individual = create(:user)

      expect { described_class.issue!(user: individual, name: "x") }
        .to raise_error(ActiveRecord::RecordInvalid, /must be a business account/)
    end

    it "requires a name of at most 60 chars" do
      expect { described_class.issue!(user: merchant, name: "") }.to raise_error(ActiveRecord::RecordInvalid)
      expect { described_class.issue!(user: merchant, name: "a" * 61) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe ".authenticate" do
    let!(:key) { described_class.issue!(user: merchant, name: "Production") }

    it "finds an active key by its plain value" do
      expect(described_class.authenticate(key.plain_token)).to eq(key)
    end

    it "rejects unknown, malformed and revoked keys" do
      expect(described_class.authenticate("kinko_sk_#{'x' * 40}")).to be_nil
      expect(described_class.authenticate("not-a-key")).to be_nil
      expect(described_class.authenticate(nil)).to be_nil

      key.revoke!
      expect(described_class.authenticate(key.plain_token)).to be_nil
    end
  end

  describe "#touch_last_used!" do
    let(:key) { described_class.issue!(user: merchant, name: "Production") }

    it "writes at most once per minute" do
      key.touch_last_used!
      first = key.reload.last_used_at
      expect(first).to be_present

      key.touch_last_used!
      expect(key.reload.last_used_at).to eq(first)

      travel 2.minutes do
        key.touch_last_used!
        expect(key.reload.last_used_at).to be > first
      end
    end
  end

  it "never exposes the digest in JSON" do
    key = described_class.issue!(user: merchant, name: "Production")
    json = key.as_json

    expect(json.keys).to contain_exactly(:id, :name, :masked_key, :created_at, :last_used_at, :revoked_at)
    expect(json[:masked_key]).to eq("kinko_sk_…#{key.last4}")
  end
end
