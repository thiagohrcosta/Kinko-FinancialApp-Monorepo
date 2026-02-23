require 'ostruct'

class Api::V1::Webhooks::StripeController < ApplicationController
  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    event = if Rails.env.development?
      # Em desenvolvimento, aceita webhooks com ou sem assinatura
      begin
        Stripe::Webhook.construct_event(
          payload,
          sig_header,
          ENV['STRIPE_WEBHOOK_SECRET']
        )
      rescue Stripe::SignatureVerificationError => e
        # Se falhar a verificação em dev, tenta parsear direto o JSON
        event_data = JSON.parse(payload)
        OpenStruct.new(
          id: event_data['id'],
          type: event_data['type'],
          data: OpenStruct.new(object: event_data['data']['object'])
        )
      end
    else
      # Em produção, sempre valida a assinatura
      begin
        Stripe::Webhook.construct_event(
          payload,
          sig_header,
          ENV['STRIPE_WEBHOOK_SECRET']
        )
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.warn("Webhook signature verification failed: #{e.message}")
        return head :unauthorized
      end
    end

    # Verifica se o evento já foi processado (idempotência)
    return head :ok unless WebhookEvent.process_once(event.id)

    case event.type
    when "payment_intent.succeeded"
      handle_success(event.data.object)
    end

    head :ok
  end

  private

  def handle_success(payment_intent)
    # Suporta tanto objetos Stripe quanto Hashes do JSON parseado
    metadata = payment_intent.is_a?(Hash) ? payment_intent["metadata"] : payment_intent.metadata
    amount_cents = payment_intent.is_a?(Hash) ? payment_intent["amount"] : payment_intent.amount

    # Acessa account_uuid - [] funciona em Hash e Stripe::StripeObject
    account_uuid = metadata["account_uuid"] if metadata

    Rails.logger.info("Processing payment_intent.succeeded: uuid=#{account_uuid}, amount=#{amount_cents}")

    return if account_uuid.blank?

    service = Payments::DepositService.new(
      account_repository: AccountRepository
    )

    service.call(
      account_uuid: account_uuid,
      amount_cents: amount_cents
    )
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
