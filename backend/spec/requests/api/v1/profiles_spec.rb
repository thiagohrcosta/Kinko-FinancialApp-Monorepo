require "rails_helper"

RSpec.describe "Api::V1::Profiles", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "GET /api/v1/profile" do
    it "returns the country and the privacy region" do
      get "/api/v1/profile", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("address_country" => "BR", "privacy_region" => "other")
      expect(response.parsed_body).not_to include("document_number", "encrypted_password")
    end

    it "says :unknown for users created before the country was asked" do
      user.update_column(:address_country, nil)

      get "/api/v1/profile", headers: headers

      expect(response.parsed_body).to include("address_country" => nil, "privacy_region" => "unknown")
    end

    it "requires a session" do
      get "/api/v1/profile"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/profile" do
    before { user.update_column(:address_country, nil) }

    it "adds the country and recomputes the region" do
      patch "/api/v1/profile", params: { address_country: "us", address_state: "ca" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("address_country" => "US", "address_state" => "CA", "privacy_region" => "us_ca")
    end

    it "rejects an invalid US state" do
      patch "/api/v1/profile", params: { address_country: "US", address_state: "Cali" }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include("State must be a US state code, e.g. CA")
    end

    it "ignores other fields" do
      patch "/api/v1/profile", params: { address_country: "DE", address_state: "Bayern", full_name: "Hacker" }, headers: headers

      expect(user.reload.full_name).to eq("Test User")
      expect(response.parsed_body["privacy_region"]).to eq("eu")
    end
  end
end
