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
        service = Accounts::ShowAccount.new
        account = service.call(user: current_user, account_id: params[:id])

        render json: account
      end
      # POST /api/v1/accounts
      def create
        service = Accounts::CreateAccount.new

        account = service.call(user: current_user)

        render json: { uuid: account.uuid }, status: :created
      end

      def balance
        account = if params[:id].nil?
          current_user.accounts.first
        else
          current_user.accounts.find_by(uuid: params[:id])
        end

        return render json: { error: 'Account not found' }, status: :not_found unless account

        start_date = 30.days.ago
        ledgers = account.ledger_entries.where('created_at >= ?', start_date)

        income = ledgers.where(entry_type: 'debit').sum(:amount_cents)
        expenses = ledgers.where(entry_type: 'credit').sum(:amount_cents)

        balance = account.ledger_entries.sum('CASE WHEN entry_type = \'debit\' THEN amount_cents ELSE -amount_cents END')

        render json: {
          balance: balance / 100.0,
          income: income / 100.0,
          expenses: expenses / 100.0,
          period: '30_days'
        }
      end

    end
  end
end