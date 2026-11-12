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

  # The id merchants see (payload "id" and the Kinko-Event-Id header).
  def self.find_by_event_id!(event_id)
    find_by!(public_id: event_id.to_s.delete_prefix("evt_"))
  end

  def event_id
    "evt_#{public_id}"
  end

  # Sends the same event again, with the same id, so a merchant that already
  # processed it can skip it. Starts a fresh retry schedule.
  def redeliver!
    update!(status: "pending", last_error: nil)
    WebhookDeliveryJob.perform_later(id)
  end
end
