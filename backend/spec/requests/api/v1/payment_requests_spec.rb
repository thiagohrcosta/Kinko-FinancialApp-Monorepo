require "rails_helper"

RSpec.describe "Api::V1::PaymentRequests (payer side)", type: :request do
  let(:merchant) { create(:user, :business) }
  let(:payer) { create(:user, full_name: "Paula Payer") }
  let(:charge) { create(:payment_request, merchant: merchant, amount_cents: 40_00, description: "Order #7") }
  let(:headers) { jwt_headers(payer) }

  before { fund(payer, 100_00) }

  describe "GET /api/v1/payment_requests/:code" do
    it "previews the payee, amount, debited account and balance" do
      get "/api/v1/payment_requests/#{charge.code}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json).to include("code" => charge.code, "status" => "pending", "amount_cents" => 40_00, "description" => "Order #7")
      expect(json["merchant"]).to include("name" => "Acme Motors", "sector" => "automotive",
                                          "account_uuid" => merchant.primary_account.uuid)
      expect(json["payer"]).to include("account_uuid" => payer.primary_account.uuid, "balance_cents" => 100_00,
                                       "sufficient_funds" => true, "is_merchant" => false, "already_paid_by_you" => false)
    end

    it "accepts a code typed with spaces and lower case" do
      get "/api/v1/payment_requests/#{ERB::Util.url_encode(charge.code.downcase.scan(/.{1,4}/).join(' '))}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "reports insufficient funds and an expired charge" do
      big = create(:payment_request, merchant: merchant, amount_cents: 500_00)
      get "/api/v1/payment_requests/#{big.code}", headers: headers
      expect(json["payer"]["sufficient_funds"]).to be(false)

      charge.update_columns(expires_at: 1.minute.ago)
      get "/api/v1/payment_requests/#{charge.code}", headers: headers
      expect(json["status"]).to eq("expired")
    end

    it "returns 422 for an invalid code and 404 for an unknown one" do
      get "/api/v1/payment_requests/KNK1NOPE", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to eq("Invalid payment code")

      get "/api/v1/payment_requests/#{Payments::PaymentCode.generate}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get "/api/v1/payment_requests/#{charge.code}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/payment_requests/:code/pay" do
    it "pays the charge" do
      post "/api/v1/payment_requests/#{charge.code}/pay", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json).to include("status" => "paid", "transaction_id" => charge.reload.public_id, "amount_cents" => 40_00)
      expect(balance_of(payer)).to eq(60_00)
      expect(balance_of(merchant)).to eq(40_00)
    end

    it "returns the same success on a repeated click" do
      2.times { post "/api/v1/payment_requests/#{charge.code}/pay", headers: headers }

      expect(response).to have_http_status(:ok)
      expect(balance_of(payer)).to eq(60_00)
    end

    it "returns 409 when someone else already paid" do
      other = create(:user, email: "other@example.com")
      fund(other, 100_00)
      post "/api/v1/payment_requests/#{charge.code}/pay", headers: jwt_headers(other)

      post "/api/v1/payment_requests/#{charge.code}/pay", headers: headers

      expect(response).to have_http_status(:conflict)
      expect(balance_of(payer)).to eq(100_00)
    end

    it "returns 422 for insufficient funds, expired, canceled and own charges" do
      big = create(:payment_request, merchant: merchant, amount_cents: 500_00)
      post "/api/v1/payment_requests/#{big.code}/pay", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to eq("Insufficient funds")

      lapsed = create(:payment_request, merchant: merchant)
      lapsed.update_columns(expires_at: 1.minute.ago)
      post "/api/v1/payment_requests/#{lapsed.code}/pay", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to eq("Payment request expired")
      expect(lapsed.reload.status).to eq("expired")

      canceled = create(:payment_request, merchant: merchant, status: "canceled", canceled_at: Time.current)
      post "/api/v1/payment_requests/#{canceled.code}/pay", headers: headers
      expect(json["error"]).to eq("Payment request canceled")

      post "/api/v1/payment_requests/#{charge.code}/pay", headers: jwt_headers(merchant)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to eq("Cannot pay your own payment request")
    end
  end

  describe "GET /api/v1/payment_requests/:code/qr" do
    it "serves the code as a public, cacheable SVG" do
      get "/api/v1/payment_requests/#{charge.code}/qr"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/svg+xml")
      expect(response.headers["Cache-Control"]).to include("public")
      expect(response.body).to include("<svg").and include('aria-label="Payment QR code"')
    end

    it "rejects invalid codes" do
      get "/api/v1/payment_requests/KNK1NOPE/qr"
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
