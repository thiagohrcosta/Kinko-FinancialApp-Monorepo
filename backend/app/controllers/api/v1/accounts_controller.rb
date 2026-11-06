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

      # GET /api/v1/accounts/balance
      def balance
        account = current_user.accounts.first
        return render json: { error: 'No accounts found for user' }, status: :not_found unless account

        period_start = 30.days.ago
        recent = account.ledger_entries.where(created_at: period_start..)

        expenses = recent.where(entry_type: :debit).sum(:amount_cents)
        income = recent.where(entry_type: :credit).sum(:amount_cents)
        balance = account.ledger_entries.sum(
          "CASE WHEN entry_type = 'credit' THEN amount_cents ELSE -amount_cents END"
        )

        render json: {
          balance: (balance / 100.0).to_s,
          income: income / 100.0,
          expenses: expenses / 100.0,
          period: "30_days"
        }
      end

      # GET /api/v1/accounts/transactions?month=YYYY-MM
      def transactions
        account = current_user.accounts.first
        return render json: { error: 'No accounts found for user' }, status: :not_found unless account

        month_start = parse_month(params[:month])
        return render json: { error: 'Invalid month format, expected YYYY-MM' }, status: :bad_request unless month_start

        ledger_entries = account.ledger_entries
          .where(created_at: month_start.beginning_of_day...month_start.next_month.beginning_of_day)
          .order(created_at: :desc, id: :desc)
          .to_a

        counterparties = counterparty_entries_for(ledger_entries)

        transactions = ledger_entries.map do |entry|
          related_user = counterparties[entry.transaction_id]&.account&.user
          counterparty_name = related_user && display_name(related_user)

          {
            id: entry.id,
            amount_cents: entry.amount_cents,
            entry_type: entry.entry_type,
            description: describe(entry, counterparty_name),
            counterparty_name: counterparty_name,
            counterparty_type: related_user&.user_type,
            counterparty_sector: related_user&.business_sector,
            created_at: entry.created_at.iso8601,
            currency: entry.currency
          }
        end

        render json: transactions
      end

      # GET /api/v1/accounts/insights?range=7|14|30
      def insights
        account = current_user.accounts.first
        unless account
          render json: { error: 'No accounts found for user' }, status: :not_found
          return
        end

        days = params[:range].to_i
        days = 7 unless [7, 14, 30].include?(days)

        period_end = Date.current
        period_start = period_end - (days - 1).days

        sums = account.ledger_entries
          .where(created_at: period_start.beginning_of_day..period_end.end_of_day)
          .group("DATE(created_at)", :entry_type)
          .sum(:amount_cents)

        dates = (period_start..period_end).to_a

        render json: {
          range: "#{days}D",
          dates: dates.map(&:iso8601),
          income: dates.map { |d| (sums[[d, "credit"]] || 0) / 100.0 },
          expenses: dates.map { |d| (sums[[d, "debit"]] || 0) / 100.0 }
        }
      end

      private

      def parse_month(value)
        return Date.current.beginning_of_month if value.blank?
        return nil unless value.to_s.match?(/\A\d{4}-\d{2}\z/)

        year, month = value.split('-').map(&:to_i)
        Date.new(year, month, 1)
      rescue Date::Error
        nil
      end

      # A outra perna de cada movimentação (mesmo transaction_id), carregada numa única query.
      def counterparty_entries_for(entries)
        entries_by_tx = entries.select { |e| e.transaction_id.present? }.index_by(&:id)
        tx_ids = entries_by_tx.values.map(&:transaction_id).uniq
        return {} if tx_ids.empty?

        LedgerEntry
          .includes(account: :user)
          .where(transaction_id: tx_ids)
          .where.not(id: entries_by_tx.keys)
          .index_by(&:transaction_id)
      end

      def display_name(user)
        user.user_type == 'business' && user.business_name.present? ? user.business_name : user.full_name
      end

      def describe(entry, counterparty_name)
        return entry.description if entry.description.present?

        if counterparty_name
          entry.credit? ? "Received from #{counterparty_name}" : "Transfer to #{counterparty_name}"
        else
          entry.credit? ? "Deposit" : "Withdrawal"
        end
      end
    end
  end
end