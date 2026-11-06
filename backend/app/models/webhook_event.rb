class WebhookEvent < ApplicationRecord
  validates :event_id, presence: true, uniqueness: true

  # Claims the event and returns true only the first time it is seen.
  #
  # Must be called inside the same transaction that applies the event's
  # effects. INSERT ... ON CONFLICT DO NOTHING on the unique index means:
  # - a redelivery after commit gets no row back → false (no double credit);
  # - a concurrent delivery waits on the uncommitted row, then gets false;
  # - if processing fails, the transaction rolls back the claim too, so the
  #   provider's retry is processed instead of being silently dropped.
  def self.process_once(event_id)
    result = insert({ event_id: event_id, status: "processed" }, unique_by: :event_id, returning: :id)
    result.rows.any?
  end
end
