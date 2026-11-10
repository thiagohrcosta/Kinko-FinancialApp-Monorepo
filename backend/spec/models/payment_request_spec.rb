require "rails_helper"

RSpec.describe PaymentRequest, type: :model do
  let(:merchant) { create(:user, :business) }
  let(:request_record) { create(:payment_request, merchant: merchant) }

  it "assigns a valid payment code and a public id on create" do
    expect(Payments::PaymentCode.valid?(request_record.code)).to be(true)
    expect(request_record.reload.public_id).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    expect(request_record.status).to eq("pending")
    expect(request_record.fee_cents).to eq(0)
  end

  describe "validations" do
    it "rejects non-positive or fractional amounts" do
      [ 0, -1, 10.5 ].each do |amount|
        expect(build(:payment_request, merchant: merchant, amount_cents: amount)).not_to be_valid
      end
    end

    it "limits description and external reference" do
      expect(build(:payment_request, merchant: merchant, description: "")).not_to be_valid
      expect(build(:payment_request, merchant: merchant, description: "a" * 141)).not_to be_valid
      expect(build(:payment_request, merchant: merchant, external_reference: "a" * 101)).not_to be_valid
    end
  end

  describe "database constraints" do
    it "refuses a non-positive amount even when validations are skipped" do
      expect { request_record.update_columns(amount_cents: 0) }.to raise_error(ActiveRecord::StatementInvalid, /amount_positive/)
    end

    it "refuses a fee above the amount" do
      expect { request_record.update_columns(fee_cents: request_record.amount_cents + 1) }
        .to raise_error(ActiveRecord::StatementInvalid, /fee_valid/)
    end

    it "refuses an unknown status" do
      expect { request_record.update_columns(status: "refunded") }.to raise_error(ActiveRecord::StatementInvalid, /status_valid/)
    end

    it "refuses a paid charge without a payer" do
      expect { request_record.update_columns(status: "paid", paid_at: Time.current) }
        .to raise_error(ActiveRecord::StatementInvalid, /paid_has_payer/)
    end
  end

  describe "#expired_now? / #effective_status" do
    it "treats a pending charge past expires_at as expired before the sweeper runs" do
      request_record.update!(expires_at: 1.second.ago)

      expect(request_record.status).to eq("pending")
      expect(request_record.expired_now?).to be(true)
      expect(request_record.effective_status).to eq("expired")
    end

    it "does not report paid or canceled charges as expired" do
      request_record.update!(status: "canceled", canceled_at: Time.current, expires_at: 1.second.ago)
      expect(request_record.effective_status).to eq("canceled")
    end
  end

  describe "#expire!" do
    let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }

    it "persists the expiry and records a payment_request.expired webhook" do
      request_record.update!(expires_at: 1.second.ago)

      expect { request_record.expire! }.to change { endpoint.deliveries.count }.by(1)
      expect(request_record.reload.status).to eq("expired")
      expect(endpoint.deliveries.last.event_type).to eq("payment_request.expired")
    end

    it "does nothing for a charge that is still valid" do
      expect { request_record.expire! }.not_to change { endpoint.deliveries.count }
      expect(request_record.reload.status).to eq("pending")
    end
  end

  describe "#as_merchant_json" do
    it "exposes the public id, never the internal id" do
      json = request_record.as_merchant_json

      expect(json[:id]).to eq(request_record.reload.public_id)
      expect(json).to include(object: "payment_request", code: request_record.code, status: "pending",
                              amount_cents: 25_00, fee_cents: 0, payer: nil)
    end
  end
end
