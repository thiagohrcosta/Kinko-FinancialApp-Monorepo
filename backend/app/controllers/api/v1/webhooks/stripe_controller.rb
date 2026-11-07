class Api::V1::Webhooks::StripeController < ApplicationController
  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    event = begin
      Stripe::Webhook.construct_event(payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"])
    rescue Stripe::SignatureVerificationError => e
      unless self.class.allow_unsigned?
        # Keeps a wrong STRIPE_WEBHOOK_SECRET visible instead of silent retries.
        Rails.logger.warn("Webhook signature verification failed: #{e.message}")
        return head :unauthorized
      end

      # Opt-in, development only: lets you replay a payload with curl.
      # `stripe listen` signs its events, so it never needs this.
      Rails.logger.warn("Accepting UNSIGNED Stripe webhook (STRIPE_WEBHOOK_ALLOW_UNSIGNED): #{e.message}")
      Stripe::Event.construct_from(JSON.parse(payload))
    end

    # Claiming the event and applying it share one transaction: a redelivery
    # is ignored, and if processing raises, the claim is rolled back and the
    # 500 makes Stripe retry it (#11).
    ActiveRecord::Base.transaction do
      next unless WebhookEvent.process_once(event.id)

      case event.type
      when "payment_intent.succeeded"
        handle_success(event.data.object)
      end
    end

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  # Unsigned webhooks are rejected unless explicitly enabled, and never
  # outside development (even if the variable leaks into another env).
  def self.allow_unsigned?
    Rails.env.development? && ENV["STRIPE_WEBHOOK_ALLOW_UNSIGNED"] == "true"
  end

  private

  def handle_success(payment_intent)
    Rails.logger.info("=== PAYMENT INTENT DEBUG ===")
    Rails.logger.info("Payment Intent: #{payment_intent.inspect}")

    metadata = payment_intent.is_a?(Hash) ? payment_intent["metadata"] : payment_intent.metadata
    amount_cents = payment_intent.is_a?(Hash) ? payment_intent["amount"] : payment_intent.amount
    account_uuid = metadata["account_uuid"] if metadata

    Rails.logger.info("Metadata: #{metadata.inspect}")
    Rails.logger.info("Account UUID: #{account_uuid}")
    Rails.logger.info("Amount: #{amount_cents}")

    if account_uuid.blank?
      Rails.logger.warn("Missing account_uuid in metadata")
      return
    end

    service = Payments::DepositService.new(
      account_repository: AccountRepository
    )

    payment_intent_id = payment_intent.is_a?(Hash) ? payment_intent["id"] : payment_intent.id
    currency = payment_intent["currency"]

    service.call(
      account_uuid: account_uuid,
      amount_cents: amount_cents,
      reference: payment_intent_id,
      currency: currency.presence || Accounts::Money::DEFAULT_CURRENCY
    )
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Account not found: #{account_uuid}")
  rescue Accounts::CurrencyMismatch
    # Permanent failure: retrying would never succeed, so do not raise.
    Rails.logger.error("Currency mismatch for #{payment_intent_id}: #{currency}")
  rescue StandardError => e
    Rails.logger.error("Error in handle_success: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))
    raise # Re-raise para ver no log
  end

  def handle_charge_success(charge)
    # Suporta tanto objetos Stripe quanto Hashes do JSON parseado
    metadata = charge.is_a?(Hash) ? charge["metadata"] : charge.metadata
    amount_cents = charge.is_a?(Hash) ? charge["amount"] : charge.amount

    # Acessa account_uuid - [] funciona em Hash e Stripe::StripeObject
    account_uuid = metadata["account_uuid"] if metadata

    Rails.logger.info("Processing charge.succeeded: uuid=#{account_uuid}, amount=#{amount_cents}")

    return if account_uuid.blank?

    service = Payments::DepositService.new(
      account_repository: AccountRepository
    )

    service.call(
      account_uuid: account_uuid,
      amount_cents: amount_cents
    )
  end
end
