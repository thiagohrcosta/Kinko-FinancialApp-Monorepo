require 'rails_helper'

RSpec.describe WebhookEvent, type: :model do
  describe ".process_once" do
    it "returns true the first time and false for the same event afterwards" do
      expect(described_class.process_once("evt_1")).to be(true)
      expect(described_class.process_once("evt_1")).to be(false)
      expect(described_class.where(event_id: "evt_1").count).to eq(1)
    end
  end
end
