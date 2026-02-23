module Api
  module V1
    class TransfersController < ApplicationController
      include Authenticatable

      def create
        from_uuid = current_user.accounts.first.uuid
        to_uuid = params.require(:destination_account_uuid)
        amount_cents = params.require(:amount_cents).to_i

        money = Accounts::Money.new(amount_cents)
        service = Transfers::TransferService.new(account_repository: AccountRepository)

        transaction_id = service.call(
          from_uuid: from_uuid,
          to_uuid: to_uuid,
          money: money
        )

        render json: {
          message: 'Transfer completed successfully',
          transaction_id: transaction_id
        }, status: :ok
      rescue ArgumentError
        render json: { error: 'Cannot transfer to the same account' }, status: :unprocessable_entity
      rescue Accounts::InsufficientFunds
        render json: { error: 'Insufficient funds' }, status: :unprocessable_entity
      rescue Accounts::InvalidAmount
        render json: { error: 'Invalid amount' }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Account not found' }, status: :not_found
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def set_current_user
        @current_user = User.find_by(uuid: params[:user_uuid])
      end
    end
  end
end