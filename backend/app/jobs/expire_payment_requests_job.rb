# Marks pending payment requests past their expiry as expired and notifies
# the merchants. Scheduled in config/recurring.yml; reads and payments also
# treat them as expired before this runs (PaymentRequest#expired_now?).
class ExpirePaymentRequestsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  def perform
    loop do
      expired = PaymentRequest.transaction do
        batch = PaymentRequest.where(status: "pending").where(expires_at: ..Time.current)
                              .order(:id).limit(BATCH_SIZE).lock("FOR UPDATE SKIP LOCKED").to_a
        batch.each(&:expire!)
        batch.size
      end
      break if expired < BATCH_SIZE
    end
  end
end
