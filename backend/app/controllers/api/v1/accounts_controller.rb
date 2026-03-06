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
        puts "DEBUG: current_user.id = #{current_user.id}"
        puts "DEBUG: current_user.email = #{current_user.email}"

        account = current_user.accounts.first
        puts "DEBUG: account = #{account.inspect}"

        unless account
          render json: { error: 'No accounts found for user' }, status: :not_found
          return
        end

        period_start = 30.days.ago
        puts "DEBUG: period_start = #{period_start}"
        puts "DEBUG: period_end = #{Time.current}"

        total_entries = account.ledger_entries.count
        puts "DEBUG: total ledger_entries = #{total_entries}"

        entries_in_period = account.ledger_entries.where(created_at: period_start..).count
        puts "DEBUG: ledger_entries in period = #{entries_in_period}"

        expenses = account.ledger_entries.where(created_at: period_start..).where(entry_type: :debit).sum(:amount_cents)
        puts "DEBUG: expenses (debit) = #{expenses}"

        income = account.ledger_entries.where(created_at: period_start..).where(entry_type: :credit).sum(:amount_cents)
        puts "DEBUG: income (credit) = #{income}"

        balance = account.ledger_entries.sum(
          "CASE WHEN entry_type = 'credit' THEN amount_cents ELSE -amount_cents END"
        )
        puts "DEBUG: balance (all time) = #{balance}"

        render json: {
          balance: (balance / 100.0).to_s,
          income: income / 100.0,
          expenses: expenses / 100.0,
          period: "30_days"
        }
      end

      def transactions
        account = current_user.accounts.first
        unless account
          render json: { error: 'No accounts found for user' }, status: :not_found
          return
        end

        month_str = params[:month]
        if month_str.blank?
          month_str = Time.current.strftime('%Y-%m')
        end

        begin
          year, month = month_str.split('-').map(&:to_i)
          month_start = Date.new(year, month, 1).beginning_of_day
          month_end = (Date.new(year, month, 1) + 1.month).end_of_day
        rescue StandardError => e
          return render json: { error: "Invalid month format: #{e.message}" }, status: :bad_request
        end

        ledger_entries = account.ledger_entries
          .where(created_at: month_start..month_end)
          .order(created_at: :desc)

        transactions = ledger_entries.map do |entry|
          description = entry.reference || "Transaction"
          counterparty_name = nil
          counterparty_type = nil
          counterparty_sector = nil

          related_entry = if entry.transaction_id.present?
            LedgerEntry.where(transaction_id: entry.transaction_id)
              .where.not(id: entry.id)
              .first
          end

          if related_entry
            related_user = related_entry.account.user
            counterparty_type = related_user.user_type
            counterparty_sector = related_user.business_sector
            counterparty_name = if related_user.user_type == 'business' && related_user.business_name.present?
                                  related_user.business_name
                                else
                                  related_user.full_name
                                end
          end

          if is_uuid?(description) || description.blank?
            if related_entry
              if entry.entry_type == 'credit'
                description = "Received from #{counterparty_name}"
              else
                description = "Transfer to #{counterparty_name}"
              end
            else
              description = entry.entry_type == 'credit' ? "Deposit" : "Withdrawal"
            end
          end

          {
            id: entry.id,
            amount_cents: entry.amount_cents,
            entry_type: entry.entry_type,
            description: description,
            counterparty_name: counterparty_name,
            counterparty_type: counterparty_type,
            counterparty_sector: counterparty_sector,
            created_at: entry.created_at.iso8601,
            currency: entry.currency
          }
        end

        render json: transactions
      end

      private

      def is_uuid?(str)
        return false if str.blank?
        str.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
      end

    end
  end
end