module Payments
  # Creates a charge for a merchant. With an idempotency key, retrying the
  # same request returns the original charge instead of creating a new one.
  class CreatePaymentRequest
    Result = Struct.new(:payment_request, :created, keyword_init: true)

    def call(merchant:, amount_cents:, description:, external_reference: nil, expires_in: nil,
             metadata: {}, idempotency_key: nil, api_key: nil)
      account = merchant.primary_account
      attrs = {
        # Integer("10.5") is nil (rejected); Integer(10.5) would silently truncate.
        amount_cents: amount_cents.is_a?(Integer) ? amount_cents : Integer(amount_cents.to_s, exception: false),
        currency: Accounts::Money::DEFAULT_CURRENCY,
        description: description.to_s.strip,
        external_reference: external_reference.presence,
        metadata: metadata.presence || {}
      }

      if idempotency_key.present?
        existing = PaymentRequest.find_by(merchant_account: account, idempotency_key: idempotency_key)
        return replay(existing, attrs) if existing
      end

      request = PaymentRequest.create!(
        **attrs,
        merchant_account: account,
        merchant_api_key: api_key,
        idempotency_key: idempotency_key.presence,
        expires_at: Time.current + ttl(expires_in)
      )
      Result.new(payment_request: request, created: true)
    rescue ActiveRecord::RecordNotUnique
      # A concurrent request with the same idempotency key won the race.
      existing = PaymentRequest.find_by!(merchant_account: account, idempotency_key: idempotency_key)
      replay(existing, attrs)
    end

    private

    def replay(existing, attrs)
      same = attrs.slice(:amount_cents, :currency, :description, :external_reference)
                  .all? { |k, v| existing.public_send(k) == v }
      raise IdempotencyConflict unless same

      Result.new(payment_request: existing, created: false)
    end

    def ttl(expires_in)
      return PaymentRequest::DEFAULT_TTL if expires_in.blank?

      seconds = Integer(expires_in, exception: false)
      raise InvalidParams, "expires_in must be an integer number of seconds" unless seconds

      seconds.seconds.clamp(PaymentRequest::MIN_TTL, PaymentRequest::MAX_TTL)
    end
  end
end
