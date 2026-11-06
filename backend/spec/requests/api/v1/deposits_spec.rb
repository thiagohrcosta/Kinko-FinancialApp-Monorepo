require 'rails_helper'

RSpec.describe "Api::V1::Deposits", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "POST /api/v1/deposits" do
    it "creates a PaymentIntent tagged with the user's account" do
      intent = double(id: "pi_123", client_secret: "pi_123_secret")
      expect(Stripe::PaymentIntent).to receive(:create)
        .with(hash_including(amount: 25_00, metadata: { account_uuid: user.accounts.first.uuid }))
        .and_return(intent)

      post "/api/v1/deposits", params: { amount_cents: 25_00 }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("payment_intent_id" => "pi_123", "client_secret" => "pi_123_secret")
    end

    it "rejects non-positive amounts without calling Stripe" do
      expect(Stripe::PaymentIntent).not_to receive(:create)

      post "/api/v1/deposits", params: { amount_cents: 0 }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns bad gateway when Stripe fails" do
      allow(Stripe::PaymentIntent).to receive(:create).and_raise(Stripe::AuthenticationError.new("bad key"))

      post "/api/v1/deposits", params: { amount_cents: 10_00 }, headers: headers

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)["error"]).to eq("Payment provider unavailable")
    end
  end
end
