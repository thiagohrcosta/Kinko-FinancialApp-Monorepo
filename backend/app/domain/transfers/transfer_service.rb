module Transfers
  class TransferService
    def initialize(account_repository:)
      @account_repository = account_repository
    end

    def call(from_uuid:, to_uuid:, money:, description: "Transfer")
      raise ArgumentError if from_uuid == to_uuid

      from_account = @account_repository.load(from_uuid)
      to_account   = @account_repository.load(to_uuid)

      from_account_record = Account.find_by!(uuid: from_uuid)
      to_account_record = Account.find_by!(uuid: to_uuid)

      to_user_name = to_account_record.user.full_name
      from_user_name = from_account_record.user.full_name

      if description == "Transfer"
        from_description = "Transfer to #{to_user_name}"
        to_description = "Received from #{from_user_name}"
      else
        from_description = "#{description} (to #{to_user_name})"
        to_description = "#{description} (from #{from_user_name})"
      end

      transaction_id = SecureRandom.uuid

      from_account.debit!(money, transaction_id: transaction_id, description: from_description)
      to_account.credit!(money, transaction_id: transaction_id, description: to_description)

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
