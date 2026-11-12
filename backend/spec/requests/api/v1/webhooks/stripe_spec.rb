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

  describe "signatures" do
    before do
      allow(Stripe::Webhook).to receive(:construct_event)
        .and_raise(Stripe::SignatureVerificationError.new("bad", "sig"))
    end

    it "rejects an invalid signature" do
      deliver(event)

      expect(response).to have_http_status(:unauthorized)
      expect(account.ledger_entries.count).to eq(0)
    end

    it "rejects unsigned events in development too, even with the old bypass variable set" do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("STRIPE_WEBHOOK_ALLOW_UNSIGNED").and_return("true")

      deliver(event)

      expect(response).to have_http_status(:unauthorized)
      expect(account.ledger_entries.count).to eq(0)
    end

    it "logs the failure so a wrong STRIPE_WEBHOOK_SECRET is visible" do
      allow(Rails.logger).to receive(:warn).and_call_original

      deliver(event)

      expect(Rails.logger).to have_received(:warn).with(/signature verification failed: bad/)
    end
  end

  it "verifies the signature with the raw body and STRIPE_WEBHOOK_SECRET" do
    deliver(event)

    expect(Stripe::Webhook).to have_received(:construct_event).with(event.to_json, anything, ENV.fetch("STRIPE_WEBHOOK_SECRET"))
  end

  describe "logs" do
    let(:logged) { [] }

    before do
      %i[info warn error].each do |level|
        allow(Rails.logger).to receive(level).and_wrap_original do |original, *args, &block|
          logged << (args.first || block&.call).to_s
          original.call(*args, &block)
        end
      end
    end

    it "log ids and amounts, never the payer's billing details" do
      event[:data][:object].merge!(receipt_email: "payer@example.com",
                                   billing_details: { name: "Jane Payer", address: { line1: "1 Main St" } })

      deliver(event)

      expect(logged).to include("Stripe pi_123: deposited 2500 cents to account #{account.uuid}")
      expect(logged.join("\n")).not_to include("Jane Payer", "1 Main St", "payer@example.com")
    end

    it "say why an event without an account is ignored" do
      event[:data][:object][:metadata] = {}

      deliver(event)

      expect(response).to have_http_status(:ok)
      expect(logged).to include("Stripe pi_123: no account_uuid in metadata, ignored")
    end

    it "say why an event for an unknown account is ignored" do
      event[:data][:object][:metadata] = { account_uuid: "00000000-0000-4000-8000-00000000ffff" }

      deliver(event)

      expect(response).to have_http_status(:ok)
      expect(logged).to include(/account 00000000-0000-4000-8000-00000000ffff not found, ignored/)
    end
  end
end
