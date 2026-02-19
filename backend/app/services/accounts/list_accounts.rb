module Accounts
  class ListAccounts
    def call(user:)
      user.accounts.map do |account_record|
        domain_account = AccountRepository.load(account_record.uuid)

        {
          uuid: domain_account.uuid,
          balance: domain_account.balance,
          status: account_record.status
        }
      end
    end
  end
end
