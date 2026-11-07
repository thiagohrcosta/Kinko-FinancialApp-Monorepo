module Api
  module V1
    module Merchant
      class ApiKeysController < ApplicationController
        include MerchantAuthenticatable
        merchant_session_only!

        # GET /api/v1/merchant/api_keys
        def index
          render json: current_merchant.merchant_api_keys.order(created_at: :desc)
        end

        # POST /api/v1/merchant/api_keys  { name }
        # The plain key is only ever returned here.
        def create
          key = MerchantApiKey.issue!(user: current_merchant, name: params.require(:name).to_s.strip)
          render json: key.as_json.merge(secret: key.plain_token), status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        rescue ActionController::ParameterMissing => e
          render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
        end

        # DELETE /api/v1/merchant/api_keys/:id  (revokes; the row is kept for audit)
        def destroy
          key = current_merchant.merchant_api_keys.find(params[:id])
          key.revoke!
          render json: key
        rescue ActiveRecord::RecordNotFound
          render json: { error: "API key not found" }, status: :not_found
        end
      end
    end
  end
end
