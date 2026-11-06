module Accounts
  class Money
    attr_reader :amount_cents, :currency

    CURRENCY_SYMBOLS = {
      "USD" => "$",
      "BRL" => "R$",
      "EUR" => "€",
      "GBP" => "£"
    }.freeze

    # The single currency of the Kinko ledger (ISO 4217, upper case).
    DEFAULT_CURRENCY = ENV.fetch("KINKO_CURRENCY", "USD").upcase.freeze

    def initialize(amount_cents, currency = DEFAULT_CURRENCY)
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
