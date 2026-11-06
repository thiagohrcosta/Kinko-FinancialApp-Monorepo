require 'rails_helper'

RSpec.describe "Api::V1::Webhooks::Stripe", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }
  let!(:system_account) { create(:account_record, uuid: ENV.fetch("SYSTEM_ACCOUNT_UUID")) }

  let(:event) do
    {
      id: "evt_123",
      type: "payment_intent.succeeded",
      data: { object: { id: "pi_123", amount: 25_00, metadata: { account_uuid: account.uuid } } }
    }
  end

  def deliver(payload)
    post "/api/v1/webhooks/stripe", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  before do
    allow(Stripe::Webhook).to receive(:construct_event) do |payload, _sig, _secret|
      Stripe::Event.construct_from(JSON.parse(payload))
    end
  end

  it "credits the account once with description and Stripe reference" do
    deliver(event)

    expect(response).to have_http_status(:ok)
    entry = account.ledger_entries.sole
    expect(entry.amount_cents).to eq(25_00)
    expect(entry.description).to eq("Deposit from Card Payment")
    expect(entry.reference).to eq("pi_123")
  end

  it "ignores a redelivered event (idempotency, #11)" do
    deliver(event)
    deliver(event)

    expect(response).to have_http_status(:ok)
    expect(account.ledger_entries.count).to eq(1)
  end

  it "does not lose the event when processing fails, so Stripe's retry credits it" do
    calls = 0
    allow_any_instance_of(Payments::DepositService).to receive(:call).and_wrap_original do |original, **kwargs|
      calls += 1
      raise "transient failure" if calls == 1

      original.call(**kwargs)
    end

    expect { deliver(event) }.to raise_error(RuntimeError, "transient failure")
    expect(WebhookEvent.where(event_id: "evt_123")).not_to exist
    expect(account.ledger_entries.count).to eq(0)

    deliver(event)

    expect(response).to have_http_status(:ok)
    expect(account.ledger_entries.count).to eq(1)
  end

  it "does not credit a payment in a different currency" do
    event[:data][:object][:currency] = "eur"

    deliver(event)

    expect(response).to have_http_status(:ok)
    expect(account.ledger_entries.count).to eq(0)
  end

  it "rejects an invalid signature outside development" do
    allow(Stripe::Webhook).to receive(:construct_event)
      .and_raise(Stripe::SignatureVerificationError.new("bad", "sig"))

    deliver(event)

    expect(response).to have_http_status(:unauthorized)
    expect(account.ledger_entries.count).to eq(0)
  end
end
