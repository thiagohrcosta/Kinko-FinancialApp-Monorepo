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

  describe "#redeliver!" do
    let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }
    let(:delivery) { described_class.enqueue_for(user: merchant, event_type: "payment_request.paid", data: {}) }

    it "sets it back to pending and enqueues it again" do
      delivery.update!(status: "failed", last_error: "HTTP 500")

      expect { delivery.redeliver! }.to have_enqueued_job(WebhookDeliveryJob).with(delivery.id)
      expect(delivery.reload).to have_attributes(status: "pending", last_error: nil)
    end
  end

  describe ".find_by_event_id!" do
    let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }

    it "finds a delivery by the id merchants see" do
      delivery = described_class.enqueue_for(user: merchant, event_type: "payment_request.paid", data: {})

      expect(described_class.find_by_event_id!(delivery.event_id)).to eq(delivery)
      expect(delivery.payload["id"]).to eq(delivery.event_id)
    end
  end
end
