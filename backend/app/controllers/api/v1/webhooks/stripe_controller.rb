class Api::V1::Webhooks::StripeController < ApplicationController
  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    if sig_header.blank? && Rails.env.development?
      event_data = JSON.parse(payload)
      event = OpenStruct.new(
        type: event_data['type'],
        data: OpenStruct.new(object: event_data['data']['object'])
      )
    else
      begin
        event = Stripe::Webhook.construct_event(
          payload,
          sig_header,
          ENV['STRIPE_WEBHOOK_SECRET']
        )
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.warn("Webhook signature verification failed: #{e.message}")
        return head :ok
      end
    end

    case event.type
    when "payment_intent.succeeded"
      handle_success(event.data.object)
    end

    head :ok
  end

  private

  def handle_success(payment_intent)
    account_uuid = payment_intent.metadata["account_uuid"]
    amount_cents = payment_intent.amount

    service = Payments::DepositService.new(
      account_repository: AccountRepository
    )

    service.call(
      account_uuid: account_uuid,
      amount_cents: amount_cents
    )
  end
end
