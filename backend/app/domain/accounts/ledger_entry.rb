module Accounts
  class LedgerEntry
    attr_reader :amount_cents, :currency, :entry_type, :reference

    def initialize(amount_cents:, currency:, entry_type:, reference: nil)
      @amount_cents = amount_cents
      @currency = "usd"
      @entry_type = entry_type
      @reference = reference

      validate!
    end

    def debit?
      entry_type == "debit"
    end

    def credit?
      entry_type == "credit"
    end

    private

    def validate!
      raise ArgumentError, "amount_cents is required" if amount_cents.nil?
      raise ArgumentError, "currency is required" if currency.nil? || currency.empty?
      raise ArgumentError, "entry_type is required" if entry_type.nil? || entry_type.empty?
      raise ArgumentError, "entry_type must be 'debit' or 'credit'" unless %w[debit credit].include?(entry_type)
    end
  end
end
