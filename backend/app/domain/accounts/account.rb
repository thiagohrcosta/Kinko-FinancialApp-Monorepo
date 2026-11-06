# app/domain/accounts/account.rb
require_relative "errors"

module Accounts
  class Account
    attr_reader :uuid, :currency

    def initialize(uuid, persisted_entries = [], currency: Money::DEFAULT_CURRENCY)
      @uuid = uuid
      @currency = currency
      @persisted_entries = persisted_entries
      @new_entries = []
    end

    def balance
      all_entries.sum(&:signed_amount)
    end

    def credit!(money, transaction_id: nil, description: nil, reference: nil)
      validate_amount!(money)

      register_entry(
        amount_cents: money.amount_cents,
        currency: money.currency,
        entry_type: :credit,
        description: description,
        transaction_id: transaction_id,
        reference: reference
      )
    end

    def debit!(money, transaction_id: nil, description: nil, reference: nil)
      validate_amount!(money)
      raise InsufficientFunds if insufficient?(money)

      register_entry(
        amount_cents: money.amount_cents,
        currency: money.currency,
        entry_type: :debit,
        description: description,
        transaction_id: transaction_id,
        reference: reference
      )
    end

    def entries
      all_entries.dup.freeze
    end

    def new_entries
      @new_entries.dup.freeze
    end

    private

    def all_entries
      @persisted_entries + @new_entries
    end

    def validate_amount!(money)
      raise InvalidAmount unless money.positive?
      # The balance is a plain sum of entries, so mixing currencies would
      # silently corrupt it.
      raise CurrencyMismatch unless money.currency == currency
    end

    def insufficient?(money)
      balance < money.amount_cents
    end

    def register_entry(**attributes)
      @new_entries << LedgerEntry.new(**attributes)
    end
  end
end
