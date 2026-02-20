module Api
  module V1
    class DepositsController < ApplicationController
      include Authenticatable

      def create
        amount_cents = amount_cents_param

        service = Payments::CreatePaymentIntent.new

        response = service.call(
          account_uuid: current_user.accounts.first.uuid,
          amount_cents: amount_cents
        )

        render json: response
      end

      private

      def amount_cents_param
        params.require(:amount_cents).to_i
      end
    end
  end
end
