# app/domain/accounts/account.rb
require_relative 'errors'

module Accounts
  class Account
    attr_reader :uuid

    def initialize(uuid, persisted_entries = [])
      @uuid = uuid
      @persisted_entries = persisted_entries
      @new_entries = []
    end

    def balance
      all_entries.sum(&:amount_cents)
    end

    def credit!(money)
      validate_amount!(money)

      register_entry(money.amount_cents)
    end

    def debit!(money)
      validate_amount!(money)
      raise InsufficientFunds if insufficient?(money)

      register_entry(-money.amount_cents)
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
    end

    def insufficient?(money)
      balance < money.amount_cents
    end

    def register_entry(amount_cents)
      @new_entries << LedgerEntry.new(amount_cents)
    end
  end
end
