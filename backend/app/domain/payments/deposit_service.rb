module Payments
  class DepositService
    SYSTEM_ACCOUNT_UUID = ENV.fetch("SYSTEM_ACCOUNT_UUID")

    def initialize(account_repository:)
      @account_repository = account_repository
    end

    def call(account_uuid:, amount_cents:)
      user_account   = @account_repository.load(account_uuid)
      system_account = @account_repository.load(SYSTEM_ACCOUNT_UUID)

      money = Accounts::Money.new(amount_cents, "USD")

      system_account.credit!(money)
      user_account.credit!(money)

      ActiveRecord::Base.transaction do
        @account_repository.save(user_account)
        @account_repository.save(system_account)
      end
    end
  end
end
