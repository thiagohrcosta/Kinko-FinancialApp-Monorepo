class WebhookEvent < ApplicationRecord
  validates :event_id, presence: true, uniqueness: true

  def self.process_once(event_id)
    create(event_id: event_id, status: 'processing')
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end
end
