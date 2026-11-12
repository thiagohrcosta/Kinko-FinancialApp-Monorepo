module Payments
  class DepositService
    SYSTEM_ACCOUNT_UUID = ENV.fetch("SYSTEM_ACCOUNT_UUID")

    def initialize(account_repository:)
      @account_repository = account_repository
    end

    # currency: ISO code reported by the payment provider. It must match the
    # Kinko ledger currency; the domain raises CurrencyMismatch otherwise.
    def call(account_uuid:, amount_cents:, reference: nil, currency: Accounts::Money::DEFAULT_CURRENCY)
      money = Accounts::Money.new(amount_cents, currency.to_s.upcase)
      transaction_id = SecureRandom.uuid

      # Double entry: the user is credited and the system account, which stands
      # for money coming from outside Kinko (card payments), is debited by the
      # same amount. Its balance is therefore minus everything ever deposited.
      @account_repository.with_locked(account_uuid, SYSTEM_ACCOUNT_UUID) do |user_account, system_account|
        user_account.credit!(money, transaction_id: transaction_id, description: "Deposit from Card Payment",
                                    reference: reference)
        system_account.debit!(money, transaction_id: transaction_id, description: "Card Payment Processed",
                                     reference: reference, allow_negative: true)
      end

      # Only notify once the deposit is committed (callers may wrap this
      # service in a larger transaction, e.g. the Stripe webhook).
      ActiveRecord.after_all_transactions_commit { notify_deposit(account_uuid, amount_cents) }
    end

    private

    def notify_deposit(account_uuid, amount_cents)
      user = Account.find_by!(uuid: account_uuid).user

      ActionCable.server.broadcast(
        "notifications:user:#{user.id}",
        {
          type: "balance_updated",
          account_uuid: account_uuid,
          amount_cents: amount_cents,
          timestamp: Time.current.iso8601
        }
      )

      Rails.logger.info("✓ Deposit notification sent to user:#{user.id}")
    rescue => e
      # A failed notification must never fail the deposit.
      Rails.logger.error("Failed to send deposit notification: #{e.message}")
    end
  end
end
