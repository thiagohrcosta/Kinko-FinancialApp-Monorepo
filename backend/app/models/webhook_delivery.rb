class WebhookDelivery < ApplicationRecord
  STATUSES = %w[pending succeeded failed].freeze

  belongs_to :webhook_endpoint

  validates :event_type, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Records the event for the merchant (if it has an active endpoint) and
  # sends it after the surrounding transaction commits, so a rolled-back
  # payment never produces a webhook.
  def self.enqueue_for(user:, event_type:, data:)
    endpoint = WebhookEndpoint.find_by(user: user, active: true)
    return unless endpoint

    delivery = endpoint.deliveries.create!(event_type: event_type, payload: {})
    delivery.update_columns(payload: {
      id: "evt_#{delivery.public_id}",
      type: event_type,
      created_at: Time.current.iso8601,
      data: data
    })
    ActiveRecord.after_all_transactions_commit { WebhookDeliveryJob.perform_later(delivery.id) }
    delivery
  end
end
