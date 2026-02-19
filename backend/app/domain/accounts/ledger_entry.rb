module Accounts
  class LedgerEntry
    attr_reader :amount_cents, :currency, :reference

    def initialize(amount_cents:, currency:, reference: nil)
      @amount_cents = amount_cents
      @currency = currency
      @reference = reference
    end
  end
end
