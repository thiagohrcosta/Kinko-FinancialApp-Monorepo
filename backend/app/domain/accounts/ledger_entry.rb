module Accounts
  class LedgerEntry
    attr_reader :amount_cents

    def initialize(amount_cents)
      @amount_cents = amount_cents
    end
  end
end
