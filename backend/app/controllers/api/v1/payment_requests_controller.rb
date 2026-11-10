module Api
  module V1
    # The payer side: a Kinko user pastes a payment code, sees who gets paid
    # and how much, then confirms.
    class PaymentRequestsController < ApplicationController
      include Authenticatable
      skip_before_action :authenticate_user!, only: :qr

      rescue_from Payments::PaymentCode::InvalidCode do |e|
        render json: { error: e.message }, status: :unprocessable_entity
      end
      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Payment request not found" }, status: :not_found
      end

      # GET /api/v1/payment_requests/:code
      def show
        request_record = find_by_code
        payer_account = current_user.primary_account
        balance = AccountRepository.load(payer_account.uuid).balance

        render json: {
          code: request_record.code,
          status: request_record.effective_status,
          amount_cents: request_record.amount_cents,
          currency: request_record.currency,
          description: request_record.description,
          expires_at: request_record.expires_at.iso8601,
          paid_at: request_record.paid_at&.iso8601,
          merchant: request_record.merchant_summary,
          payer: {
            account_uuid: payer_account.uuid,
            balance_cents: balance,
            sufficient_funds: balance >= request_record.amount_cents,
            is_merchant: request_record.merchant_account_id == payer_account.id,
            already_paid_by_you: request_record.paid? && request_record.payer_account_id == payer_account.id
          }
        }
      end

      # POST /api/v1/payment_requests/:code/pay
      def pay
        paid = Payments::PayPaymentRequest.new.call(code: params[:code], payer: current_user)
        render json: {
          status: "paid",
          transaction_id: paid.public_id,
          amount_cents: paid.amount_cents,
          currency: paid.currency,
          paid_at: paid.paid_at.iso8601,
          merchant: paid.merchant_summary
        }
      rescue Payments::AlreadyPaid => e
        render json: { error: e.message }, status: :conflict
      rescue Payments::NotPayable => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Accounts::InsufficientFunds
        render json: { error: "Insufficient funds" }, status: :unprocessable_entity
      end

      # GET /api/v1/payment_requests/:code/qr  → image/svg+xml (public)
      # The QR only encodes the code itself, which carries no payment data.
      def qr
        code = Payments::PaymentCode.normalize!(params[:code])
        svg = RQRCode::QRCode.new(code, level: :m).as_svg(module_size: 6, standalone: true, use_path: true,
                                                          viewbox: true, svg_attributes: { role: "img", "aria-label": "Payment QR code" })
        expires_in 1.day, public: true
        send_data svg, type: "image/svg+xml", disposition: "inline"
      end

      private

      def find_by_code
        PaymentRequest.includes(merchant_account: :user).find_by!(code: Payments::PaymentCode.normalize!(params[:code]))
      end
    end
  end
end
