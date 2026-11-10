module Payments
  class PaymentError < StandardError; end

  class NotPayable < PaymentError; end

  # Invalid input from the merchant (message is safe to return).
  class InvalidParams < PaymentError; end

  class AlreadyPaid < NotPayable
    def initialize(msg = "Payment request already paid")
      super
    end
  end

  class Expired < NotPayable
    def initialize(msg = "Payment request expired")
      super
    end
  end

  class Canceled < NotPayable
    def initialize(msg = "Payment request canceled")
      super
    end
  end

  class OwnPaymentRequest < NotPayable
    def initialize(msg = "Cannot pay your own payment request")
      super
    end
  end

  class IdempotencyConflict < PaymentError
    def initialize(msg = "Idempotency-Key was already used with different parameters")
      super
    end
  end

  class NotCancelable < PaymentError
    def initialize(msg = "Only pending payment requests can be canceled")
      super
    end
  end
end
