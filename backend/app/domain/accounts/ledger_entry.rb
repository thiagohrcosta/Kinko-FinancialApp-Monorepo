module Accounts
  class LedgerEntry
    attr_reader :amount_cents, :currency, :entry_type, :description, :transaction_id, :reference

    # amount_cents é sempre positivo; o sinal vem de entry_type (ver #signed_amount).
    # description: texto legível exibido no extrato.
    # transaction_id: agrupa as duas pernas de uma movimentação (ex.: transferência).
    # reference: identificador externo opcional (ex.: id do PaymentIntent no Stripe).
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
