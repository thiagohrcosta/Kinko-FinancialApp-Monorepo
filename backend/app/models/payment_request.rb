# A charge created by a merchant and paid by a Kinko user with the
# copy-and-paste code (or its QR code).
class PaymentRequest < ApplicationRecord
  STATUSES = %w[pending paid canceled expired].freeze
  DEFAULT_TTL = 24.hours
  MAX_TTL = 30.days
  MIN_TTL = 5.minutes

  belongs_to :merchant_account, class_name: "Account"
  belongs_to :payer_account, class_name: "Account", optional: true
  belongs_to :merchant_api_key, optional: true

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true
  validates :description, presence: true, length: { maximum: 140 }
  validates :external_reference, length: { maximum: 100 }
  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true

  before_validation :assign_code, on: :create

  STATUSES.each do |s|
    define_method(:"#{s}?") { status == s }
  end

  # pending past expires_at is effectively expired, even before the sweeper
  # job (ExpirePaymentRequestsJob) persists it.
  def expired_now?
    expired? || (pending? && expires_at <= Time.current)
  end

  # Call with the row locked (or from the sweeper's locked batch).
  def expire!
    return unless pending? && expires_at <= Time.current

    update!(status: "expired")
    WebhookDelivery.enqueue_for(user: merchant_user, event_type: "payment_request.expired", data: as_merchant_json)
  end

  def merchant_user
    merchant_account.user
  end

  def merchant_display_name
    merchant_user.display_name
  end

  def merchant_summary
    { name: merchant_display_name, sector: merchant_user.business_sector, account_uuid: merchant_account.uuid }
  end

  def effective_status
    expired_now? ? "expired" : status
  end

  # The representation returned to merchants (API and webhooks).
  def as_merchant_json
    {
      id: public_id,
      object: "payment_request",
      code: code,
      status: effective_status,
      amount_cents: amount_cents,
      fee_cents: fee_cents,
      currency: currency,
      description: description,
      external_reference: external_reference,
      metadata: metadata,
      expires_at: expires_at.iso8601,
      paid_at: paid_at&.iso8601,
      canceled_at: canceled_at&.iso8601,
      payer: payer_account && { account_uuid: payer_account.uuid, name: payer_account.user.full_name },
      created_at: created_at.iso8601
    }
  end

  private

  def assign_code
    self.code ||= loop do
      candidate = Payments::PaymentCode.generate
      break candidate unless self.class.exists?(code: candidate)
    end
  end
end
