require "rails_helper"

RSpec.describe "Api::V1::Merchant::PaymentRequests", type: :request do
  let(:merchant) { create(:user, :business) }
  let(:key) { MerchantApiKey.issue!(user: merchant, name: "Integration") }
  let(:headers) { api_key_headers(key) }
  let(:params) { { amount_cents: 129_90, description: "Order #1001", external_reference: "ord_1001" } }

  describe "POST /api/v1/merchant/payment_requests" do
    it "creates a charge with a payment code" do
      post "/api/v1/merchant/payment_requests", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json).to include("object" => "payment_request", "status" => "pending", "amount_cents" => 129_90,
                              "fee_cents" => 0, "external_reference" => "ord_1001")
      expect(Payments::PaymentCode.valid?(json["code"])).to be(true)
      expect(PaymentRequest.find_by(public_id: json["id"]).merchant_api_key).to eq(key)
    end

    it "accepts string metadata and caps it at 20 keys" do
      post "/api/v1/merchant/payment_requests", params: params.merge(metadata: { order: 1, sku: "A" }), headers: headers, as: :json
      expect(json["metadata"]).to eq("order" => "1", "sku" => "A")

      too_many = (1..21).to_h { |i| [ "k#{i}", "v" ] }
      post "/api/v1/merchant/payment_requests", params: params.merge(metadata: too_many), headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      post "/api/v1/merchant/payment_requests", params: params.merge(metadata: "nope"), headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "replays the original charge for the same Idempotency-Key" do
      post "/api/v1/merchant/payment_requests", params: params, headers: headers.merge("Idempotency-Key" => "abc"), as: :json
      first = json

      post "/api/v1/merchant/payment_requests", params: params, headers: headers.merge("Idempotency-Key" => "abc"), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(first["id"])
      expect(PaymentRequest.count).to eq(1)
    end

    it "returns 409 when an Idempotency-Key is reused with different parameters" do
      post "/api/v1/merchant/payment_requests", params: params, headers: headers.merge("Idempotency-Key" => "abc"), as: :json
      post "/api/v1/merchant/payment_requests", params: params.merge(amount_cents: 1), headers: headers.merge("Idempotency-Key" => "abc"), as: :json

      expect(response).to have_http_status(:conflict)
    end

    it "validates input" do
      post "/api/v1/merchant/payment_requests", params: params.except(:amount_cents), headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
      expect(json["error"]).to eq("Missing parameter: amount_cents")

      post "/api/v1/merchant/payment_requests", params: params.merge(amount_cents: 10.5), headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      post "/api/v1/merchant/payment_requests", params: params.merge(expires_in: "soon"), headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to match(/expires_in/)
    end
  end

  describe "GET /api/v1/merchant/payment_requests" do
    let(:other_merchant) { create(:user, :business, email: "other@example.com") }

    before do
      create(:payment_request, merchant: merchant, description: "pending one")
      lapsed = create(:payment_request, merchant: merchant, description: "lapsed one")
      lapsed.update_columns(expires_at: 1.minute.ago)
      create(:payment_request, merchant: merchant, description: "canceled one", status: "canceled", canceled_at: Time.current)
      create(:payment_request, merchant: other_merchant, description: "not mine")
    end

    it "lists only the merchant's own charges" do
      get "/api/v1/merchant/payment_requests", headers: headers

      expect(json["data"].map { |r| r["description"] }).to contain_exactly("pending one", "lapsed one", "canceled one")
    end

    it "filters by effective status" do
      get "/api/v1/merchant/payment_requests", params: { status: "pending" }, headers: headers
      expect(json["data"].map { |r| r["description"] }).to eq([ "pending one" ])

      get "/api/v1/merchant/payment_requests", params: { status: "expired" }, headers: headers
      expect(json["data"].map { |r| [ r["description"], r["status"] ] }).to eq([ [ "lapsed one", "expired" ] ])
    end

    it "paginates with a clamped limit" do
      get "/api/v1/merchant/payment_requests", params: { limit: 1, offset: 1 }, headers: headers
      expect(json).to include("limit" => 1, "offset" => 1)
      expect(json["data"].size).to eq(1)

      get "/api/v1/merchant/payment_requests", params: { limit: 10_000, offset: -5 }, headers: headers
      expect(json).to include("limit" => 100, "offset" => 0)
    end
  end

  describe "GET /api/v1/merchant/payment_requests/:id" do
    it "shows a charge by public id and hides other merchants' charges" do
      mine = create(:payment_request, merchant: merchant).reload
      theirs = create(:payment_request, merchant: create(:user, :business, email: "other@example.com")).reload

      get "/api/v1/merchant/payment_requests/#{mine.public_id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(mine.public_id)

      get "/api/v1/merchant/payment_requests/#{theirs.public_id}", headers: headers
      expect(response).to have_http_status(:not_found)

      get "/api/v1/merchant/payment_requests/#{mine.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/merchant/payment_requests/:id/cancel" do
    it "cancels a pending charge" do
      charge = create(:payment_request, merchant: merchant).reload

      post "/api/v1/merchant/payment_requests/#{charge.public_id}/cancel", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["status"]).to eq("canceled")
    end

    it "refuses to cancel twice" do
      charge = create(:payment_request, merchant: merchant, status: "canceled", canceled_at: Time.current).reload

      post "/api/v1/merchant/payment_requests/#{charge.public_id}/cancel", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
