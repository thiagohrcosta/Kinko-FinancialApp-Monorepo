module Accounts
  class LedgerEntry
    attr_reader :amount_cents, :currency, :entry_type, :description, :transaction_id, :reference

    # amount_cents is always positive; the sign comes from entry_type (see #signed_amount).
    # description: human-readable text shown in the statement.
    # transaction_id: links both legs of a movement (e.g. a transfer).
    # reference: optional external identifier (e.g. the Stripe PaymentIntent id).
    def initialize(amount_cents:, currency:, entry_type:, description: nil, transaction_id: nil, reference: nil)
      raise InvalidAmount unless amount_cents.positive?
      raise InvalidEntryType unless %i[credit debit].include?(entry_type)

      @amount_cents = amount_cents
      @currency = currency
      @entry_type = entry_type
      @description = description
      @transaction_id = transaction_id
      @reference = reference
    end

    def signed_amount
      entry_type == :credit ? amount_cents : -amount_cents
    end
  end
end
