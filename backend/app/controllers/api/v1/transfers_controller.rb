module Api
  module V1
    class TransfersController < ApplicationController
      include Authenticatable

      def create
        from_uuid = current_user.accounts.first.uuid
        to_uuid = params.require(:destination_account_uuid)
        amount_cents = params.require(:amount_cents).to_i
        description = params[:description] || "Transfer"

        if to_uuid == from_uuid
          return render json: { error: "Cannot transfer to the same account" }, status: :unprocessable_entity
        end

        money = Accounts::Money.new(amount_cents)
        service = Transfers::TransferService.new(account_repository: AccountRepository)

        transaction_id = service.call(
          from_uuid: from_uuid,
          to_uuid: to_uuid,
          money: money,
          description: description
        )

        render json: {
          message: "Transfer completed successfully",
          transaction_id: transaction_id
        }, status: :ok
      rescue ActionController::ParameterMissing => e
        render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
      rescue Accounts::InsufficientFunds
        render json: { error: "Insufficient funds" }, status: :unprocessable_entity
      rescue Accounts::InvalidAmount
        render json: { error: "Invalid amount" }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Account not found" }, status: :not_found
      rescue => e
        # Details go to the log only; the client gets a generic message and
        # a request id to correlate with it.
        Rails.logger.error("Transfer failed [#{request.request_id}]: #{e.class} - #{e.message}")
        render json: { error: "Internal error", request_id: request.request_id }, status: :internal_server_error
      end
    end
  end
end
