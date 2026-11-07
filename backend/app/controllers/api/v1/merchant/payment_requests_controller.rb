module Api
  module V1
    module Merchant
      # Charges, for API integrations (Kinko API key) and the merchant dashboard (JWT).
      class PaymentRequestsController < ApplicationController
        include MerchantAuthenticatable

        MAX_LIMIT = 100

        rescue_from ActiveRecord::RecordNotFound do
          render json: { error: "Payment request not found" }, status: :not_found
        end

        # GET /api/v1/merchant/payment_requests?status=paid&limit=20&offset=0
        def index
          scope = PaymentRequest.where(merchant_account: current_merchant.accounts)
                                .includes(payer_account: :user).order(created_at: :desc, id: :desc)
          scope = filter_status(scope, params[:status]) if params[:status].present?
          limit = params.fetch(:limit, 20).to_i.clamp(1, MAX_LIMIT)
          offset = [ params[:offset].to_i, 0 ].max

          render json: { data: scope.limit(limit).offset(offset).map(&:as_merchant_json), limit: limit, offset: offset }
        end

        # GET /api/v1/merchant/payment_requests/:id
        def show
          render json: find_request.as_merchant_json
        end

        # POST /api/v1/merchant/payment_requests
        #   { amount_cents, description, external_reference?, expires_in?, metadata? }
        #   Header Idempotency-Key (recommended): a retry returns the original charge.
        def create
          result = Payments::CreatePaymentRequest.new.call(
            merchant: current_merchant,
            amount_cents: params.require(:amount_cents),
            description: params.require(:description),
            external_reference: params[:external_reference],
            expires_in: params[:expires_in],
            metadata: metadata_param,
            idempotency_key: request.headers["Idempotency-Key"].presence,
            api_key: current_api_key
          )
          render json: result.payment_request.as_merchant_json, status: result.created ? :created : :ok
        rescue ActionController::ParameterMissing => e
          render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
        rescue Payments::IdempotencyConflict => e
          render json: { error: e.message }, status: :conflict
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        rescue Payments::InvalidParams => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        # POST /api/v1/merchant/payment_requests/:id/cancel
        def cancel
          render json: Payments::CancelPaymentRequest.new.call(payment_request: find_request).as_merchant_json
        rescue Payments::NotCancelable => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def find_request
          PaymentRequest.where(merchant_account: current_merchant.accounts).find_by!(public_id: params[:id])
        end

        def filter_status(scope, status)
          now = Time.current
          case status
          when "expired" then scope.where(status: "expired").or(scope.where(status: "pending", expires_at: ..now))
          when "pending" then scope.where(status: "pending").where("expires_at > ?", now)
          else scope.where(status: status)
          end
        end

        # Free-form string key/values for the merchant's own use (max 20 keys).
        def metadata_param
          raw = params[:metadata]
          return {} if raw.blank?
          raise Payments::InvalidParams, "metadata must be an object" unless raw.respond_to?(:to_unsafe_h)

          hash = raw.to_unsafe_h.transform_values(&:to_s)
          raise Payments::InvalidParams, "metadata accepts at most 20 keys" if hash.size > 20

          hash.to_h { |k, v| [ k.to_s.first(40), v.first(500) ] }
        end
      end
    end
  end
end
