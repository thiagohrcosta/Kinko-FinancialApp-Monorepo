require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  let(:merchant) { create(:user, :business) }

  describe ".enqueue_for" do
    it "does nothing when the merchant has no active endpoint" do
      expect(described_class.enqueue_for(user: merchant, event_type: "payment_request.paid", data: {})).to be_nil

      WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks", active: false)
      expect(described_class.enqueue_for(user: merchant, event_type: "payment_request.paid", data: {})).to be_nil
      expect(described_class.count).to eq(0)
    end

    it "writes the event payload and enqueues the job only after commit" do
      endpoint = WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks")

      delivery = nil
      expect {
        ActiveRecord::Base.transaction do
          delivery = described_class.enqueue_for(user: merchant, event_type: "payment_request.paid", data: { id: "x" })
          expect(enqueued_jobs.size).to eq(0)
        end
      }.to have_enqueued_job(WebhookDeliveryJob).exactly(:once)

      expect(WebhookDeliveryJob).to have_been_enqueued.with(delivery.id)
      delivery.reload
      expect(delivery.webhook_endpoint).to eq(endpoint)
      expect(delivery.status).to eq("pending")
      expect(delivery.payload).to include("id" => "evt_#{delivery.public_id}", "type" => "payment_request.paid",
                                          "data" => { "id" => "x" })
    end

    it "enqueues nothing when the surrounding transaction rolls back" do
      WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks")

      expect {
        ActiveRecord::Base.transaction do
          described_class.enqueue_for(user: merchant, event_type: "payment_request.paid", data: {})
          raise ActiveRecord::Rollback
        end
      }.not_to have_enqueued_job(WebhookDeliveryJob)
      expect(described_class.count).to eq(0)
    end
  end
end
