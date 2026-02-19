module Api
  module V1
    class AccountsController < ApplicationController
      include Authenticatable

      # GET /api/v1/accounts
      def index
        service = Accounts::ListAccounts.new
        accounts = service.call(user: current_user)

        render json: accounts
      end

      # GET /api/v1/accounts/{uuid}
      def show
        service = Accounts::ListAccount.new
        account = service.call(user: current_user, account_id: params[:id])

        render json: account
      end
      # POST /api/v1/accounts
      def create
        service = Accounts::CreateAccount.new

        account = service.call(user: current_user)

        render json: { uuid: account.uuid }, status: :created
      end

    end
  end
end