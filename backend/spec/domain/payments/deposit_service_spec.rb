require "rails_helper"

RSpec.describe Payments::DepositService do
  subject(:service) { described_class.new(account_repository: AccountRepository) }

  let!(:system_account) { create(:account_record, uuid: ENV.fetch("SYSTEM_ACCOUNT_UUID")) }
  let(:user) { create(:user) }
  let(:account) { user.primary_account }

  def balance(record) = AccountRepository.load(record.uuid).balance

  it "credits the user and debits the system account by the same amount" do
    service.call(account_uuid: account.uuid, amount_cents: 50_00, reference: "pi_1")

    expect(balance(account)).to eq(50_00)
    expect(balance(system_account)).to eq(-50_00)
  end

  it "leaves the ledger balanced: both legs of a deposit sum to zero" do
    service.call(account_uuid: account.uuid, amount_cents: 50_00, reference: "pi_1")
    service.call(account_uuid: account.uuid, amount_cents: 20_00, reference: "pi_2")

    expect(LedgerEntry.all.sum { |e| e.entry_type == "credit" ? e.amount_cents : -e.amount_cents }).to eq(0)
    LedgerEntry.group(:transaction_id).count.each_value { |legs| expect(legs).to eq(2) }
  end

  it "links both legs with one transaction id and the payment reference" do
    service.call(account_uuid: account.uuid, amount_cents: 50_00, reference: "pi_1")

    credit = account.ledger_entries.sole
    debit = system_account.ledger_entries.sole
    expect([ credit.entry_type, debit.entry_type ]).to eq(%w[credit debit])
    expect(debit.transaction_id).to eq(credit.transaction_id).and be_present
    expect([ credit.reference, debit.reference ]).to all(eq("pi_1"))
  end

  it "applies a payment reference only once" do
    service.call(account_uuid: account.uuid, amount_cents: 50_00, reference: "pi_1")

    expect {
      service.call(account_uuid: account.uuid, amount_cents: 50_00, reference: "pi_1")
    }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(balance(account)).to eq(50_00)
    expect(balance(system_account)).to eq(-50_00)
  end
end
