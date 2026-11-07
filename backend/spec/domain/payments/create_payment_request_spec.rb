require "rails_helper"

RSpec.describe Payments::CreatePaymentRequest do
  let(:merchant) { create(:user, :business) }
  let(:service) { described_class.new }
  let(:base) { { merchant: merchant, amount_cents: 150_00, description: "Order #42" } }

  it "creates a pending charge on the merchant's primary account" do
    result = service.call(**base, external_reference: "ord_42", metadata: { "sku" => "A1" })

    expect(result.created).to be(true)
    request = result.payment_request
    expect(request).to be_persisted
    expect(request).to have_attributes(merchant_account: merchant.primary_account, amount_cents: 150_00,
                                       currency: Accounts::Money::DEFAULT_CURRENCY, status: "pending",
                                       external_reference: "ord_42", metadata: { "sku" => "A1" })
  end

  it "accepts the amount as a string of digits (form params)" do
    expect(service.call(**base, amount_cents: "1999").payment_request.amount_cents).to eq(1999)
  end

  it "rejects fractional, non-numeric and non-positive amounts" do
    [ "10.5", 10.5, "abc", "0", -5 ].each do |amount|
      expect { service.call(**base, amount_cents: amount) }.to raise_error(ActiveRecord::RecordInvalid), "accepted #{amount.inspect}"
    end
  end

  describe "expires_in" do
    it "defaults to 24 hours" do
      freeze_time do
        expect(service.call(**base).payment_request.expires_at).to eq(24.hours.from_now)
      end
    end

    it "is clamped between 5 minutes and 30 days" do
      freeze_time do
        expect(service.call(**base, expires_in: 1).payment_request.expires_at).to eq(5.minutes.from_now)
        expect(service.call(**base, expires_in: 90.days.to_i).payment_request.expires_at).to eq(30.days.from_now)
        expect(service.call(**base, expires_in: "3600").payment_request.expires_at).to eq(1.hour.from_now)
      end
    end

    it "must be an integer" do
      expect { service.call(**base, expires_in: "1h") }.to raise_error(Payments::InvalidParams)
    end
  end

  describe "idempotency" do
    it "returns the original charge when the same key is retried" do
      first = service.call(**base, idempotency_key: "key-1")
      second = service.call(**base, idempotency_key: "key-1")

      expect(second.created).to be(false)
      expect(second.payment_request).to eq(first.payment_request)
      expect(PaymentRequest.count).to eq(1)
    end

    it "raises a conflict when the key is reused with different parameters" do
      service.call(**base, idempotency_key: "key-1")

      expect { service.call(**base, amount_cents: 1, idempotency_key: "key-1") }.to raise_error(Payments::IdempotencyConflict)
      expect { service.call(**base, description: "other", idempotency_key: "key-1") }.to raise_error(Payments::IdempotencyConflict)
    end

    it "scopes keys per merchant" do
      other = create(:user, :business, email: "other@example.com")

      a = service.call(**base, idempotency_key: "shared")
      b = service.call(**base, merchant: other, idempotency_key: "shared")

      expect(b.created).to be(true)
      expect(b.payment_request).not_to eq(a.payment_request)
    end

    it "recovers when a concurrent request with the same key wins the insert race" do
      winner = service.call(**base, idempotency_key: "race").payment_request
      # Simulate the race: the first lookup misses (the other request had not
      # committed yet), then the insert hits the unique index.
      calls = 0
      allow(PaymentRequest).to receive(:find_by).and_wrap_original do |original, *args, **kwargs|
        calls += 1
        calls == 1 ? nil : original.call(*args, **kwargs)
      end

      result = service.call(**base, idempotency_key: "race")

      expect(result.created).to be(false)
      expect(result.payment_request).to eq(winner)
    end
  end
end
