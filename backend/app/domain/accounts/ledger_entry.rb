module Accounts
  class LedgerEntry
    attr_reader :amount_cents, :currency, :entry_type, :reference

    def initialize(amount_cents:, currency:, entry_type:, reference: nil)
      raise InvalidAmount unless amount_cents.positive?
      raise InvalidEntryType unless %i[credit debit].include?(entry_type)

      @amount_cents = amount_cents
      @currency = currency
      @entry_type = entry_type
      @reference = reference
    end

    def signed_amount
      entry_type == :credit ? amount_cents : -amount_cents
    end
  end
end