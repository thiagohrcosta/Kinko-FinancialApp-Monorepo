module Transfers
  class TransferService
    def initialize(account_repository:)
      @account_repository = account_repository
    end

    def call(from_uuid:, to_uuid:, money:, description: "Transfer")
      raise ArgumentError if from_uuid == to_uuid

      from_user_name = ::Account.includes(:user).find_by!(uuid: from_uuid).user.full_name
      to_user_name   = ::Account.includes(:user).find_by!(uuid: to_uuid).user.full_name

      if description == "Transfer"
        from_description = "Transfer to #{to_user_name}"
        to_description = "Received from #{from_user_name}"
      else
        from_description = "#{description} (to #{to_user_name})"
        to_description = "#{description} (from #{from_user_name})"
      end

      transaction_id = SecureRandom.uuid

      # Both accounts are locked, so the balance checked by debit! is the
      # balance at commit time (no double spending under concurrency).
      @account_repository.with_locked(from_uuid, to_uuid) do |from_account, to_account|
        from_account.debit!(money, transaction_id: transaction_id, description: from_description)
        to_account.credit!(money, transaction_id: transaction_id, description: to_description)
      end

      transaction_id
    end
  end
end
