module Accounts
  class CreateAccount
    def call(user:)
      ::Account.create!(
        user: user,
        status: "active"
      )
    end
  end
end
