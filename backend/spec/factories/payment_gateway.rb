FactoryBot.define do
  factory :payment_request do
    transient do
      merchant { association(:user, :business) }
    end

    merchant_account { merchant.primary_account }
    amount_cents { 25_00 }
    currency { "USD" }
    description { "Order #1001" }
    expires_at { 1.hour.from_now }
  end
end
