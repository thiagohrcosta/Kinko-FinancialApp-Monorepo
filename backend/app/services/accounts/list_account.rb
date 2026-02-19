module Accounts
  class ListAccount
    def call(user:, account_id:)
      account = user.accounts.find_by!(uuid: account_id)
      domain_account = AccountRepository.load(account.uuid)
      {
        uuid: domain_account.uuid,
        balance: domain_account.balance,
        status: account.status
      }
    end
  end
end
