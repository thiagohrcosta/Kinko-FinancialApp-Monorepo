require "rails_helper"

# Who can reach the merchant API, and with which credential.
RSpec.describe "Merchant API authentication", type: :request do
  let(:merchant) { create(:user, :business) }
  let(:key) { MerchantApiKey.issue!(user: merchant, name: "Integration") }

  describe "payment requests (API key or dashboard session)" do
    it "accepts a Kinko API key" do
      get "/api/v1/merchant/payment_requests", headers: api_key_headers(key)
      expect(response).to have_http_status(:ok)
    end

    it "accepts the merchant's JWT" do
      get "/api/v1/merchant/payment_requests", headers: jwt_headers(merchant)
      expect(response).to have_http_status(:ok)
    end

    it "updates last_used_at when an API key is used" do
      expect { get "/api/v1/merchant/payment_requests", headers: api_key_headers(key) }
        .to change { key.reload.last_used_at }.from(nil)
    end

    it "rejects a missing header, an unknown key and a revoked key with 401" do
      get "/api/v1/merchant/payment_requests"
      expect(response).to have_http_status(:unauthorized)

      get "/api/v1/merchant/payment_requests", headers: { "Authorization" => "Bearer kinko_sk_#{'x' * 40}" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid API key")

      key.revoke!
      get "/api/v1/merchant/payment_requests", headers: api_key_headers(key)
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an invalid JWT with 401" do
      get "/api/v1/merchant/payment_requests", headers: { "Authorization" => "Bearer not.a.jwt" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects individual (non-business) users with 403" do
      get "/api/v1/merchant/payment_requests", headers: jwt_headers(create(:user))
      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq("Business account required")
    end

    it "rejects a key whose owner is no longer a business account" do
      key
      merchant.update_columns(user_type: "individual")

      get "/api/v1/merchant/payment_requests", headers: api_key_headers(key)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "credential management (dashboard session only)" do
    it "refuses an API key on api_keys and webhook_endpoint, so a leaked key cannot mint new keys" do
      post "/api/v1/merchant/api_keys", params: { name: "evil" }, headers: api_key_headers(key)
      expect(response).to have_http_status(:forbidden)

      get "/api/v1/merchant/api_keys", headers: api_key_headers(key)
      expect(response).to have_http_status(:forbidden)

      get "/api/v1/merchant/webhook_endpoint", headers: api_key_headers(key)
      expect(response).to have_http_status(:forbidden)

      expect(merchant.merchant_api_keys.count).to eq(1)
    end
  end
end
