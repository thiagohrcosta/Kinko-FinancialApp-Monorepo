require "rails_helper"

RSpec.describe ExpirePaymentRequestsJob, type: :job do
  let(:merchant) { create(:user, :business) }
  let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }

  it "expires only pending charges past expires_at and notifies the merchant" do
    lapsed = create(:payment_request, merchant: merchant)
    lapsed.update_columns(expires_at: 1.minute.ago)
    live = create(:payment_request, merchant: merchant, expires_at: 1.hour.from_now)
    canceled = create(:payment_request, merchant: merchant, status: "canceled", canceled_at: Time.current)
    canceled.update_columns(expires_at: 1.minute.ago)

    described_class.perform_now

    expect(lapsed.reload.status).to eq("expired")
    expect(live.reload.status).to eq("pending")
    expect(canceled.reload.status).to eq("canceled")
    expect(endpoint.deliveries.pluck(:event_type)).to eq([ "payment_request.expired" ])
  end

  it "processes more than one batch" do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    records = Array.new(5) { create(:payment_request, merchant: merchant) }
    PaymentRequest.where(id: records.map(&:id)).update_all(expires_at: 1.minute.ago)

    described_class.perform_now

    expect(PaymentRequest.where(id: records.map(&:id)).pluck(:status).uniq).to eq([ "expired" ])
  end

  it "is scheduled every 5 minutes in production" do
    recurring = YAML.load(ERB.new(File.read(Rails.root.join("config/recurring.yml"))).result)

    expect(recurring.dig("production", "expire_payment_requests")).to include("class" => "ExpirePaymentRequestsJob",
                                                                               "schedule" => "every 5 minutes")
  end
end
