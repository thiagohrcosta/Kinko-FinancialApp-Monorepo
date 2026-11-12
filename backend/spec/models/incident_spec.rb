require "rails_helper"

RSpec.describe Incident do
  let(:window) { { from: 2.days.ago, to: 1.day.ago } }

  def affected(tables, exposure: :snapshot, **range)
    described_class.affected_users(**window.merge(range), tables: tables, exposure: exposure)
  end

  describe ".affected_users" do
    let!(:early) { travel_to(10.days.ago) { create(:user) } }
    let!(:during) { travel_to(36.hours.ago) { create(:user) } }
    let!(:late) { create(:user) }

    it "with a snapshot exposure, includes everyone who existed at the end of the window" do
      expect(affected(%w[users])).to contain_exactly(early, during)
    end

    it "with an activity exposure, includes only rows created or changed in the window" do
      expect(affected(%w[users], exposure: :activity)).to contain_exactly(during)
    end

    it "finds users through their ledger entries" do
      travel_to(36.hours.ago) { create(:ledger_entry_record, account_record: late.primary_account, amount_cents: 100) }

      expect(affected(%w[ledger_entries], exposure: :activity)).to contain_exactly(late)
    end

    it "finds both the merchant and the payer of a charge" do
      merchant = create(:user, :business)
      charge = travel_to(36.hours.ago) do
        create(:payment_request, merchant_account: merchant.primary_account, payer_account: late.primary_account)
      end

      expect(affected(%w[payment_requests], exposure: :activity)).to contain_exactly(merchant, late)
      expect(charge).to be_persisted
    end

    it "finds the merchant and the payer named in a webhook payload" do
      merchant = create(:user, :business)
      WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks")
      travel_to(36.hours.ago) do
        WebhookDelivery.enqueue_for(user: merchant, event_type: "payment_request.paid",
                                    data: { payer: { account_uuid: late.primary_account.uuid, name: late.full_name } })
      end

      expect(affected(%w[webhook_deliveries], exposure: :activity)).to contain_exactly(merchant, late)
    end

    it "rejects unknown tables and exposures" do
      expect { affected(%w[secrets]) }.to raise_error(ArgumentError, /Unknown tables: secrets/)
      expect { affected(%w[users], exposure: :all) }.to raise_error(ArgumentError, /exposure/)
    end
  end

  describe ".to_csv" do
    it "has what's needed to decide who must be notified" do
      user = create(:user, address_state: "CA")

      rows = CSV.parse(described_class.to_csv(User.where(id: user.id)), headers: true)

      expect(rows.headers).to eq(described_class::CSV_COLUMNS)
      expect(rows.first.to_h).to include("id" => user.id.to_s, "email" => user.email, "address_state" => "CA")
      expect(rows.first["privacy_region"]).to be_present
    end
  end

  describe "containment" do
    let(:merchant) { create(:user, :business) }

    it "revokes every active API key" do
      keys = Array.new(2) { MerchantApiKey.issue!(user: merchant, name: "Server") }
      keys.first.revoke!

      expect(described_class.revoke_all_api_keys!).to eq(1)
      expect(MerchantApiKey.active).to be_empty
    end

    it "disables every webhook endpoint" do
      WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks")

      expect(described_class.disable_all_webhooks!).to eq(1)
      expect(WebhookEndpoint.where(active: true)).to be_empty
    end

    it "rotates every webhook secret" do
      endpoint = WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks")

      expect { described_class.rotate_all_webhook_secrets! }.to change { endpoint.reload.signing_secret }
    end
  end
end
