module Api
  module V1
    class DepositsController < ApplicationController
      include Authenticatable

      # POST /api/v1/deposits
      # Cria um PaymentIntent no Stripe. O crédito no ledger só acontece
      # quando o webhook payment_intent.succeeded chega.
      def create
        amount_cents = amount_cents_param
        unless amount_cents.positive?
          return render json: { error: "Invalid amount" }, status: :unprocessable_entity
        end

        service = Payments::CreatePaymentIntent.new

        response = service.call(
          account_uuid: current_user.accounts.first.uuid,
          amount_cents: amount_cents
        )

        render json: response
      rescue Stripe::StripeError => e
        Rails.logger.error("Stripe error creating PaymentIntent: #{e.class} - #{e.message}")
        render json: { error: "Payment provider unavailable" }, status: :bad_gateway
      end

      private

      def amount_cents_param
        params.require(:amount_cents).to_i
      end
    end
  end
end
