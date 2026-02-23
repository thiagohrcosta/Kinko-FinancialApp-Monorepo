module Transfers
  class TransferService
    def initialize(account_repository:)
      @account_repository = account_repository
    end

    def call(from_uuid:, to_uuid:, money:)
      raise ArgumentError if from_uuid == to_uuid

      from_account = @account_repository.load(from_uuid)
      to_account   = @account_repository.load(to_uuid)

      transaction_id = SecureRandom.uuid

      from_account.debit!(money, transaction_id: transaction_id)
      to_account.credit!(money, transaction_id: transaction_id)

      persist!(from_account, to_account)
      transaction_id
    end

    private

    def persist!(from_account, to_account)
      ActiveRecord::Base.transaction do
        @account_repository.save(from_account)
        @account_repository.save(to_account)
      end
    end
  end
end
