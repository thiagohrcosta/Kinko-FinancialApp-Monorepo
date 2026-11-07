require "rails_helper"

# Real concurrent transactions need real commits, so this file opts out of
# transactional tests and cleans up after itself.
RSpec.describe "Concurrent payment request payments", type: :model do
  self.use_transactional_tests = false

  let!(:merchant) { create(:user, :business) }
  let!(:payers) { Array.new(2) { create(:user) } }
  let(:users) { [ merchant, *payers ] }

  after do
    account_ids = users.flat_map { |u| u.accounts.ids }
    WebhookDelivery.joins(:webhook_endpoint).where(webhook_endpoints: { user_id: users.map(&:id) }).delete_all
    WebhookEndpoint.where(user_id: users.map(&:id)).delete_all
    PaymentRequest.where(merchant_account_id: account_ids).delete_all
    LedgerEntry.where(account_id: account_ids).delete_all
    Account.where(id: account_ids).delete_all
    User.where(id: users.map(&:id)).delete_all
  end

  def race(count)
    barrier = Concurrent::CyclicBarrier.new(count)
    Array.new(count) do |i|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          barrier.wait
          yield(i)
        end
      end
    end.map(&:value)
  end

  it "charges exactly once when two payers race for the same charge" do
    charge = create(:payment_request, merchant: merchant, amount_cents: 30_00)
    payers.each { |p| fund(p, 100_00) }
    WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks")

    results = race(2) do |i|
      Payments::PayPaymentRequest.new.call(code: charge.code, payer: payers[i])
      :paid
    rescue Payments::AlreadyPaid
      :already_paid
    end

    expect(results).to contain_exactly(:paid, :already_paid)
    expect(balance_of(merchant)).to eq(30_00)
    expect(payers.map { |p| balance_of(p) }).to contain_exactly(70_00, 100_00)
    expect(WebhookDelivery.where(event_type: "payment_request.paid").count).to eq(1)
  end

  it "debits once when the same payer double-submits" do
    charge = create(:payment_request, merchant: merchant, amount_cents: 30_00)
    fund(payers.first, 100_00)

    results = race(3) { Payments::PayPaymentRequest.new.call(code: charge.code, payer: payers.first).status }

    expect(results).to all(eq("paid"))
    expect(balance_of(payers.first)).to eq(70_00)
    expect(LedgerEntry.where(transaction_id: charge.reload.public_id).count).to eq(2)
  end

  it "never overdraws when one payer pays two charges at the same time" do
    charges = Array.new(2) { create(:payment_request, merchant: merchant, amount_cents: 60_00) }
    fund(payers.first, 100_00)

    results = race(2) do |i|
      Payments::PayPaymentRequest.new.call(code: charges[i].code, payer: payers.first)
      :paid
    rescue Accounts::InsufficientFunds
      :insufficient
    end

    expect(results).to contain_exactly(:paid, :insufficient)
    expect(balance_of(payers.first)).to eq(40_00)
  end
end
