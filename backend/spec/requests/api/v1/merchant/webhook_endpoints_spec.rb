require "rails_helper"

RSpec.describe "Api::V1::Merchant::WebhookEndpoints", type: :request do
  let(:merchant) { create(:user, :business) }
  let(:headers) { jwt_headers(merchant) }

  it "returns an empty state before configuration" do
    get "/api/v1/merchant/webhook_endpoint", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json).to eq("endpoint" => nil, "deliveries" => [])
  end

  it "configures the URL and returns the signing secret" do
    put "/api/v1/merchant/webhook_endpoint", params: { url: "https://merchant.example/hooks" }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["endpoint"]).to include("url" => "https://merchant.example/hooks", "active" => true)
    expect(json["endpoint"]["signing_secret"]).to start_with("kinko_whsec_")
  end

  it "keeps the secret when the URL changes and re-enables a disabled endpoint" do
    endpoint = WebhookEndpoint.create!(user: merchant, url: "https://a.example/hooks", active: false)
    secret = endpoint.signing_secret

    put "/api/v1/merchant/webhook_endpoint", params: { url: "https://b.example/hooks" }, headers: headers

    expect(endpoint.reload).to have_attributes(url: "https://b.example/hooks", active: true, signing_secret: secret)
  end

  it "rejects unsafe URLs" do
    allow(WebhookEndpoint).to receive(:allow_insecure?).and_return(false)
    allow(Resolv).to receive(:getaddresses).and_return([ "10.0.0.1" ])

    put "/api/v1/merchant/webhook_endpoint", params: { url: "https://internal.example/hooks" }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("Url must be a public https URL")
  end

  it "rotates the secret" do
    endpoint = WebhookEndpoint.create!(user: merchant, url: "https://a.example/hooks")

    post "/api/v1/merchant/webhook_endpoint/rotate_secret", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["endpoint"]["signing_secret"]).not_to eq(endpoint.signing_secret)
    expect(endpoint.reload.signing_secret).to eq(json["endpoint"]["signing_secret"])
  end

  it "returns 404 when rotating without an endpoint" do
    post "/api/v1/merchant/webhook_endpoint/rotate_secret", headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it "disables delivery on DELETE" do
    endpoint = WebhookEndpoint.create!(user: merchant, url: "https://a.example/hooks")

    delete "/api/v1/merchant/webhook_endpoint", headers: headers

    expect(response).to have_http_status(:no_content)
    expect(endpoint.reload.active).to be(false)
  end

  it "lists the latest deliveries" do
    WebhookEndpoint.create!(user: merchant, url: "https://a.example/hooks")
    delivery = WebhookDelivery.enqueue_for(user: merchant, event_type: "payment_request.paid", data: {})

    get "/api/v1/merchant/webhook_endpoint", headers: headers

    expect(json["deliveries"].first).to include("id" => "evt_#{delivery.reload.public_id}",
                                                "event_type" => "payment_request.paid", "status" => "pending")
  end
end
