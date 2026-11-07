require "rails_helper"

RSpec.describe "Api::V1::Merchant::ApiKeys", type: :request do
  let(:merchant) { create(:user, :business) }
  let(:headers) { jwt_headers(merchant) }

  it "creates a key and returns the secret only once" do
    post "/api/v1/merchant/api_keys", params: { name: " Production " }, headers: headers

    expect(response).to have_http_status(:created)
    expect(json["name"]).to eq("Production")
    expect(json["secret"]).to start_with("kinko_sk_")
    secret = json["secret"]
    expect(json["masked_key"]).to eq("kinko_sk_…#{secret[-4..]}")

    get "/api/v1/merchant/api_keys", headers: headers
    expect(response.body).not_to include(secret)
    expect(json.first).not_to have_key("secret")
  end

  it "requires a name" do
    post "/api/v1/merchant/api_keys", params: {}, headers: headers
    expect(response).to have_http_status(:bad_request)

    post "/api/v1/merchant/api_keys", params: { name: "a" * 61 }, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "lists only the merchant's own keys, newest first" do
    old = MerchantApiKey.issue!(user: merchant, name: "old")
    travel 1.minute do
      MerchantApiKey.issue!(user: merchant, name: "new")
    end
    MerchantApiKey.issue!(user: create(:user, :business, email: "other@example.com"), name: "theirs")

    get "/api/v1/merchant/api_keys", headers: headers

    expect(json.map { |k| k["name"] }).to eq(%w[new old])
    expect(json.last["id"]).to eq(old.id)
  end

  it "revokes a key, keeping the row for audit" do
    key = MerchantApiKey.issue!(user: merchant, name: "Production")

    delete "/api/v1/merchant/api_keys/#{key.id}", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["revoked_at"]).to be_present
    expect(MerchantApiKey.authenticate(key.plain_token)).to be_nil
    expect(MerchantApiKey.exists?(key.id)).to be(true)
  end

  it "cannot revoke another merchant's key" do
    theirs = MerchantApiKey.issue!(user: create(:user, :business, email: "other@example.com"), name: "theirs")

    delete "/api/v1/merchant/api_keys/#{theirs.id}", headers: headers

    expect(response).to have_http_status(:not_found)
    expect(theirs.reload.revoked_at).to be_nil
  end
end
