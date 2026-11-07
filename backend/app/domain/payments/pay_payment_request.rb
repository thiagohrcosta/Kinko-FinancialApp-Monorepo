module Payments
  # Pays a payment request from the payer's Kinko balance.
  #
  # Exactly-once, even with double clicks, two tabs or retries:
  # - the payment request row is locked first (SELECT ... FOR UPDATE), so two
  #   attempts are serialized and the second one sees status "paid";
  # - both accounts are then locked by AccountRepository.with_locked, so the
  #   balance check cannot race other debits;
  # - the ledger legs use the payment request's public_id as transaction_id,
  #   and the unique (account_id, transaction_id) index makes a second debit
  #   impossible even if the code above had a bug.
  class PayPaymentRequest
    def initialize(account_repository: AccountRepository)
      @account_repository = account_repository
    end

    def call(code:, payer:)
      payer_account = payer.primary_account
      expired = false

      result = ActiveRecord::Base.transaction do
        request = PaymentRequest.lock.find_by!(code: PaymentCode.normalize!(code))

        # Paying again a request this payer already paid is a no-op: the
        # client (double click, retry) gets the same successful result.
        next request if request.paid? && request.payer_account_id == payer_account.id

        ensure_payable!(request, payer_account)

        if request.expired_now?
          # Persist the expiration (and its webhook) before refusing: raising
          # here would roll it back.
          request.expire!
          expired = true
          next nil
        end

        money = Accounts::Money.new(request.amount_cents, request.currency)
        transaction_id = request.public_id

        @account_repository.with_locked(payer_account.uuid, request.merchant_account.uuid) do |from, to|
          from.debit!(money, transaction_id: transaction_id,
                             description: "Payment to #{request.merchant_display_name}: #{request.description}")
          to.credit!(money, transaction_id: transaction_id,
                            description: "Payment from #{payer.full_name}: #{request.description}")
        end

        request.update!(status: "paid", paid_at: Time.current, payer_account: payer_account)

        WebhookDelivery.enqueue_for(user: request.merchant_user, event_type: "payment_request.paid",
                                    data: request.as_merchant_json)
        request
      end

      raise Expired if expired

      result
    end

    private

    def ensure_payable!(request, payer_account)
      raise AlreadyPaid if request.paid?
      raise Canceled if request.canceled?
      raise Expired if request.expired?
      raise OwnPaymentRequest if request.merchant_account_id == payer_account.id
    end
  end
end
