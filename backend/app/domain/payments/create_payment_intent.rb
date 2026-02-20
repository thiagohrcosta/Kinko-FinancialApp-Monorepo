module Payments
  class CreatePaymentIntent
    def call(account_uuid:, amount_cents:)
      intent = Stripe::PaymentIntent.create(
        amount: amount_cents,
        currency: "usd",
        payment_method_types: ["card"],
        metadata: {
          account_uuid: account_uuid
        }
      )

      {
        payment_intent_id: intent.id,
        client_secret: intent.client_secret
      }
    end
  end
end
