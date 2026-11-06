class WebhookEvent < ApplicationRecord
  validates :event_id, presence: true, uniqueness: true

  # Records the event and returns true only the first time it is seen.
  # `create!` is required: `create` swallows the uniqueness failure (no
  # RecordInvalid is raised), so a Stripe redelivery would credit the deposit
  # twice. RecordNotUnique covers two concurrent deliveries (unique index).
  def self.process_once(event_id)
    create!(event_id: event_id, status: "processing")
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    false
  end
end
