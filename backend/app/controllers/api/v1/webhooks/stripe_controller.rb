# Stripe events. Every event must be signed with STRIPE_WEBHOOK_SECRET, in
# every environment: in development, `stripe listen` signs the events it
# forwards (see backend/README.md).
class Api::V1::Webhooks::StripeController < ApplicationController
  def create
    event = Stripe::Webhook.construct_event(request.body.read, request.env["HTTP_STRIPE_SIGNATURE"],
                                            ENV["STRIPE_WEBHOOK_SECRET"])

    # Claiming the event and applying it share one transaction: a redelivery
    # is ignored, and if processing raises, the claim is rolled back and the
    # 500 makes Stripe retry it (#11).
    ActiveRecord::Base.transaction do
      next unless WebhookEvent.process_once(event.id)

      deposit(event.data.object) if event.type == "payment_intent.succeeded"
    end

    head :ok
  rescue Stripe::SignatureVerificationError => e
    # Keeps a wrong STRIPE_WEBHOOK_SECRET visible instead of silent retries.
    Rails.logger.warn("Stripe webhook signature verification failed: #{e.message}")
    head :unauthorized
  rescue JSON::ParserError
    head :bad_request
  end

  private
    # Logs ids and amounts only: a PaymentIntent can carry the payer's billing
    # details, which must not end up in the logs (#96).
    def deposit(payment_intent)
      account_uuid = payment_intent["metadata"]&.[]("account_uuid")
      if account_uuid.blank?
        Rails.logger.warn("Stripe #{payment_intent.id}: no account_uuid in metadata, ignored")
        return
      end

      Payments::DepositService.new(account_repository: AccountRepository).call(
        account_uuid: account_uuid,
        amount_cents: payment_intent.amount,
        reference: payment_intent.id,
        currency: payment_intent["currency"].presence || Accounts::Money::DEFAULT_CURRENCY
      )
      Rails.logger.info("Stripe #{payment_intent.id}: deposited #{payment_intent.amount} cents to account #{account_uuid}")
    # Permanent failures: retrying would never succeed, so answer 200.
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Stripe #{payment_intent.id}: account #{account_uuid} not found, ignored")
    rescue Accounts::CurrencyMismatch
      Rails.logger.error("Stripe #{payment_intent.id}: currency #{payment_intent['currency']} doesn't match the ledger, ignored")
    end
end
