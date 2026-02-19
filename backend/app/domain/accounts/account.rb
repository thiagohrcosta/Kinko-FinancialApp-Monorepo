# app/domain/accounts/account.rb
require_relative 'errors'

module Accounts
  class Account
    attr_reader :uuid, :entries

    def initialize(uuid, entries = [])
      @uuid = uuid
      @entries = entries
    end

    def balance
      entries.sum(&:amount_cents)
    end

    def credit!(money)
      raise InvalidAmount unless money.positive?

      add_entry(money.amount_cents)
    end

    def debit!(money)
      raise InvalidAmount unless money.positive?
      raise InsufficientFunds if insufficient?(money)

      add_entry(-money.amount_cents)
    end

    private

    def insufficient?(money)
      balance < money.amount_cents
    end

    def add_entry(amount_cents)
      entries << LedgerEntry.new(amount_cents)
    end
  end
end