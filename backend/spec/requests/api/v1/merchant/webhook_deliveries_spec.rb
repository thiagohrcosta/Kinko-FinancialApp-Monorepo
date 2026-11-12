require "rails_helper"

RSpec.describe "Api::V1::Merchant::WebhookDeliveries", type: :request do
  let(:merchant) { create(:user, :business) }
  let(:headers) { jwt_headers(merchant) }
  let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }
  let!(:delivery) do
    WebhookDelivery.enqueue_for(user: merchant, event_type: "payment_request.paid", data: { id: "pr_1" })
                   .tap { |d| d.update!(status: "failed", attempts: 8, last_error: "HTTP 500") }
  end

  def redeliver(id = delivery.event_id, as: headers)
    post "/api/v1/merchant/webhook_deliveries/#{id}/redeliver", headers: as
  end

  it "resends a failed delivery with the same event id" do
    expect { redeliver }.to have_enqueued_job(WebhookDeliveryJob).with(delivery.id)

    expect(response).to have_http_status(:accepted)
    expect(json).to eq("id" => delivery.event_id, "status" => "pending")
    expect(delivery.reload).to have_attributes(status: "pending", last_error: nil)
  end

  it "resends a delivery that already succeeded" do
    delivery.update!(status: "succeeded")

    expect { redeliver }.to have_enqueued_job(WebhookDeliveryJob)
    expect(response).to have_http_status(:accepted)
  end

  it "refuses while the delivery is still being retried" do
    delivery.update!(status: "pending")

    expect { redeliver }.not_to have_enqueued_job(WebhookDeliveryJob)
    expect(response).to have_http_status(:conflict)
  end

  it "refuses when the endpoint is disabled" do
    endpoint.update!(active: false)

    redeliver

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "can't resend another merchant's delivery" do
    other = create(:user, :business)
    WebhookEndpoint.create!(user: other, url: "https://other.example/hooks")

    redeliver(delivery.event_id, as: jwt_headers(other))

    expect(response).to have_http_status(:not_found)
    expect(delivery.reload.status).to eq("failed")
  end

  it "answers 404 for unknown ids" do
    redeliver("evt_00000000-0000-4000-8000-000000000000")

    expect(response).to have_http_status(:not_found)
  end

  it "requires a dashboard session, not an API key" do
    key = MerchantApiKey.issue!(user: merchant, name: "Server")

    redeliver(delivery.event_id, as: api_key_headers(key))

    expect(response).to have_http_status(:forbidden)
  end
end
