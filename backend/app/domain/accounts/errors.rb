module Accounts
  class DomainError < StandardError; end

  class InvalidAmount < DomainError
    def initialize(msg = "Amount must be positive")
      super
    end
  end

  class InsufficientFunds < DomainError
    def initialize(msg = "Insufficient funds for this operation")
      super
    end
  end

  class AccountNotFound < DomainError; end
  class InvalidAccount < DomainError; end
end