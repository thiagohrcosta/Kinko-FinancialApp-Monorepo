module Api
  module V1
    module Merchant
      # Resend a webhook the merchant missed, e.g. after their server was down
      # longer than the retry schedule (#48).
      class WebhookDeliveriesController < ApplicationController
        include MerchantAuthenticatable
        merchant_session_only!

        rate_limit to: 30, within: 1.minute, only: :redeliver,
                   with: -> { render json: { error: "Too many redeliveries, try again in a minute" }, status: :too_many_requests }

        # POST /api/v1/merchant/webhook_deliveries/:id/redeliver   (:id is the event id, evt_…)
        def redeliver
          endpoint = current_merchant.webhook_endpoint
          delivery = endpoint&.deliveries&.find_by_event_id!(params[:id])
          return render json: { error: "Webhook delivery not found" }, status: :not_found unless delivery
          return render json: { error: "Webhook endpoint is disabled" }, status: :unprocessable_entity unless endpoint.active?
          return render json: { error: "This delivery is still being retried" }, status: :conflict if delivery.status == "pending"

          delivery.redeliver!
          render json: { id: delivery.event_id, status: delivery.status }, status: :accepted
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Webhook delivery not found" }, status: :not_found
        end
      end
    end
  end
end
