require "rails_helper"

RSpec.describe Payments::CancelPaymentRequest do
  let(:merchant) { create(:user, :business) }
  let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }
  let(:charge) { create(:payment_request, merchant: merchant) }

  it "cancels a pending charge and records a payment_request.canceled webhook" do
    described_class.new.call(payment_request: charge)

    expect(charge.reload).to have_attributes(status: "canceled")
    expect(charge.canceled_at).to be_present
    expect(endpoint.deliveries.pluck(:event_type)).to eq([ "payment_request.canceled" ])
  end

  it "refuses paid, canceled and expired charges" do
    payer = create(:user, email: "payer@example.com")
    paid = create(:payment_request, merchant: merchant, status: "paid", paid_at: Time.current, payer_account: payer.primary_account)
    canceled = create(:payment_request, merchant: merchant, status: "canceled", canceled_at: Time.current)
    lapsed = create(:payment_request, merchant: merchant)
    lapsed.update_columns(expires_at: 1.minute.ago)

    [ paid, canceled, lapsed ].each do |record|
      expect { described_class.new.call(payment_request: record) }.to raise_error(Payments::NotCancelable)
    end
    expect(endpoint.deliveries.count).to eq(0)
  end
end
