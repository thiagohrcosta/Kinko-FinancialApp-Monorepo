module Api
  module V1
    module Merchant
      # The merchant's single webhook endpoint (singular resource).
      class WebhookEndpointsController < ApplicationController
        include MerchantAuthenticatable
        merchant_session_only!

        # GET /api/v1/merchant/webhook_endpoint
        def show
          endpoint = current_merchant.webhook_endpoint
          return render json: { endpoint: nil, deliveries: [] } unless endpoint

          deliveries = endpoint.deliveries.order(created_at: :desc).limit(20).map do |d|
            { id: d.payload["id"], event_type: d.event_type, status: d.status, attempts: d.attempts,
              last_response_code: d.last_response_code, last_error: d.last_error,
              created_at: d.created_at.iso8601, delivered_at: d.delivered_at&.iso8601 }
          end
          render json: { endpoint: endpoint, deliveries: deliveries }
        end

        # PUT /api/v1/merchant/webhook_endpoint  { url }
        def update
          endpoint = current_merchant.webhook_endpoint || current_merchant.build_webhook_endpoint
          endpoint.assign_attributes(url: params.require(:url).to_s.strip, active: true)
          created = endpoint.new_record?
          if endpoint.save
            # A new endpoint gets a new secret: the only time it's shown, with rotate_secret.
            render json: { endpoint: created ? with_secret(endpoint) : endpoint }
          else
            render json: { errors: endpoint.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActionController::ParameterMissing => e
          render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
        end

        # POST /api/v1/merchant/webhook_endpoint/rotate_secret
        def rotate_secret
          endpoint = current_merchant.webhook_endpoint
          return render json: { error: "Webhook endpoint not configured" }, status: :not_found unless endpoint

          endpoint.rotate_secret!
          render json: { endpoint: with_secret(endpoint) }
        end

        # DELETE /api/v1/merchant/webhook_endpoint  (disables delivery)
        def destroy
          current_merchant.webhook_endpoint&.update!(active: false)
          head :no_content
        end

        private
          def with_secret(endpoint)
            endpoint.as_json.merge(signing_secret: endpoint.signing_secret)
          end
      end
    end
  end
end
