module Payments
  class CancelPaymentRequest
    def call(payment_request:)
      PaymentRequest.transaction do
        payment_request.lock!
        raise NotCancelable unless payment_request.pending? && !payment_request.expired_now?

        payment_request.update!(status: "canceled", canceled_at: Time.current)
        WebhookDelivery.enqueue_for(user: payment_request.merchant_user, event_type: "payment_request.canceled",
                                    data: payment_request.as_merchant_json)
      end
      payment_request
    end
  end
end
