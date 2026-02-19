module Accounts
  class Money
    attr_reader :amount_cents, :currency

    CURRENCY_SYMBOLS = {
      'USD' => '$',
      'BRL' => 'R$',
      'EUR' => '€',
      'GBP' => '£'
    }.freeze

    def initialize(amount_cents, currency = 'USD')
      @amount_cents = amount_cents
      @currency = currency
    end

    def positive?
      amount_cents > 0
    end

    def zero?
      amount_cents == 0
    end

    def negative?
      amount_cents < 0
    end

    def ==(other)
      return false unless other.is_a?(Money)
      amount_cents == other.amount_cents && currency == other.currency
    end

    def to_s
      symbol = CURRENCY_SYMBOLS.fetch(currency, currency)
      "#{symbol}#{(amount_cents / 100.0).round(2)}"
    end
  end
end