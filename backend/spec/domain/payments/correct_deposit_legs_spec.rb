require "rails_helper"

RSpec.describe Payments::CorrectDepositLegs do
  let!(:system_account) { create(:account_record, uuid: ENV.fetch("SYSTEM_ACCOUNT_UUID")) }
  let(:user_account) { create(:user).primary_account }

  def balance(record) = AccountRepository.load(record.uuid).balance

  # What DepositService wrote before #12 was fixed.
  def old_deposit(amount_cents, reference)
    user_account.ledger_entries.create!(amount_cents: amount_cents, currency: "USD", entry_type: "credit",
                                        description: "Deposit from Card Payment", reference: reference)
    system_account.ledger_entries.create!(amount_cents: amount_cents, currency: "USD", entry_type: "credit",
                                          description: "Card Payment Processed", reference: reference)
  end

  before do
    old_deposit(50_00, "pi_1")
    old_deposit(20_00, "pi_2")
  end

  it "only reports in a dry run" do
    result = described_class.new.call

    expect(result.to_h).to eq(legs: 2, amount_cents: 70_00)
    expect(balance(system_account)).to eq(70_00)
  end

  it "brings the system account to minus everything deposited, with new entries only" do
    expect { described_class.new.call(apply: true) }.not_to change { LedgerEntry.where(entry_type: "credit").count }

    expect(balance(system_account)).to eq(-70_00)
    expect(balance(user_account)).to eq(70_00)
    expect(system_account.ledger_entries.where(entry_type: "debit").pluck(:reference)).to contain_exactly("fix-12:pi_1", "fix-12:pi_2")
  end

  it "is idempotent" do
    described_class.new.call(apply: true)

    expect(described_class.new.call(apply: true).legs).to eq(0)
    expect(balance(system_account)).to eq(-70_00)
  end

  it "leaves deposits made after the fix alone" do
    described_class.new.call(apply: true)
    Payments::DepositService.new(account_repository: AccountRepository)
                            .call(account_uuid: user_account.uuid, amount_cents: 10_00, reference: "pi_3")

    expect(described_class.new.call.legs).to eq(0)
    expect(balance(system_account)).to eq(-80_00)
  end
end
