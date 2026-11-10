require "rails_helper"

RSpec.describe Payments::PayPaymentRequest do
  let(:merchant) { create(:user, :business) }
  let(:payer) { create(:user, full_name: "Paula Payer") }
  let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }
  let(:charge) { create(:payment_request, merchant: merchant, amount_cents: 40_00, description: "Order #7") }
  let(:service) { described_class.new }

  before { fund(payer, 100_00) }

  it "debits the payer, credits the merchant and marks the charge paid" do
    paid = service.call(code: charge.code, payer: payer)

    expect(paid).to have_attributes(status: "paid", payer_account: payer.primary_account)
    expect(paid.paid_at).to be_present
    expect(balance_of(payer)).to eq(60_00)
    expect(balance_of(merchant)).to eq(40_00)
  end

  it "links both ledger legs to the charge's public id" do
    service.call(code: charge.code, payer: payer)
    public_id = charge.reload.public_id

    debit = payer.primary_account.ledger_entries.find_by(entry_type: "debit")
    credit = merchant.primary_account.ledger_entries.find_by(entry_type: "credit")
    expect([ debit.transaction_id, credit.transaction_id ]).to all(eq(public_id))
    expect(debit.description).to eq("Payment to Acme Motors: Order #7")
    expect(credit.description).to eq("Payment from Paula Payer: Order #7")
  end

  it "records a payment_request.paid webhook" do
    service.call(code: charge.code, payer: payer)

    delivery = endpoint.deliveries.last
    expect(delivery.event_type).to eq("payment_request.paid")
    expect(delivery.payload["data"]).to include("id" => charge.reload.public_id, "status" => "paid")
  end

  it "accepts the code in any case and with spaces" do
    messy = charge.code.downcase.scan(/.{1,4}/).join(" ")
    expect(service.call(code: messy, payer: payer)).to be_paid
  end

  it "is a no-op when the same payer pays again (double click)" do
    first = service.call(code: charge.code, payer: payer)
    second = service.call(code: charge.code, payer: payer)

    expect(second).to eq(first)
    expect(balance_of(payer)).to eq(60_00)
    expect(endpoint.deliveries.count).to eq(1)
  end

  it "refuses a charge already paid by someone else" do
    service.call(code: charge.code, payer: payer)
    other = create(:user, email: "other@example.com")
    fund(other, 100_00)

    expect { service.call(code: charge.code, payer: other) }.to raise_error(Payments::AlreadyPaid)
    expect(balance_of(other)).to eq(100_00)
  end

  it "refuses insufficient funds without changing anything" do
    big = create(:payment_request, merchant: merchant, amount_cents: 500_00)

    expect { service.call(code: big.code, payer: payer) }.to raise_error(Accounts::InsufficientFunds)
    expect(big.reload).to be_pending
    expect(balance_of(payer)).to eq(100_00)
    expect(endpoint.deliveries.count).to eq(0)
  end

  it "refuses canceled charges" do
    charge.update!(status: "canceled", canceled_at: Time.current)
    expect { service.call(code: charge.code, payer: payer) }.to raise_error(Payments::Canceled)
  end

  it "refuses the merchant paying its own charge" do
    fund(merchant, 100_00)
    expect { service.call(code: charge.code, payer: merchant) }.to raise_error(Payments::OwnPaymentRequest)
  end

  it "refuses an expired charge but persists the expiry and its webhook" do
    charge.update!(expires_at: 1.second.ago)

    expect { service.call(code: charge.code, payer: payer) }.to raise_error(Payments::Expired)
    expect(charge.reload.status).to eq("expired")
    expect(endpoint.deliveries.pluck(:event_type)).to eq([ "payment_request.expired" ])
    expect(balance_of(payer)).to eq(100_00)
  end

  it "rejects invalid codes before touching the database" do
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?("payment_requests") }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      expect { service.call(code: "KNK1INVALID", payer: payer) }.to raise_error(Payments::PaymentCode::InvalidCode)
    end
    expect(queries).to be_empty
  end

  it "raises not found for a well-formed code with no charge" do
    expect { service.call(code: Payments::PaymentCode.generate, payer: payer) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
