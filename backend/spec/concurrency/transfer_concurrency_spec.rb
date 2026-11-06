require "rails_helper"

# Real concurrent transactions need real commits, so this file opts out of
# transactional tests and cleans up after itself.
RSpec.describe "Concurrent transfers", type: :model do
  self.use_transactional_tests = false

  let!(:alice) { create(:user) }
  let!(:bob) { create(:user) }
  let!(:carol) { create(:user) }
  let(:alice_account) { alice.accounts.first }

  before { create(:ledger_entry_record, account_record: alice_account, amount_cents: 100_00) }

  after do
    LedgerEntry.where(account_id: [ alice, bob, carol ].flat_map { |u| u.accounts.ids }).delete_all
    [ alice, bob, carol ].each { |u| u.accounts.delete_all }
    User.where(id: [ alice.id, bob.id, carol.id ]).delete_all
  end

  it "never lets two simultaneous debits overdraw the account" do
    service = Transfers::TransferService.new(account_repository: AccountRepository)
    destinations = [ bob, carol ].map { |u| u.accounts.first.uuid }

    barrier = Concurrent::CyclicBarrier.new(destinations.size)
    results = destinations.map do |to_uuid|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          barrier.wait
          service.call(from_uuid: alice_account.uuid, to_uuid: to_uuid, money: Accounts::Money.new(60_00))
          :ok
        rescue Accounts::InsufficientFunds
          :insufficient
        end
      end
    end.map(&:value)

    expect(results).to contain_exactly(:ok, :insufficient)
    expect(AccountRepository.load(alice_account.uuid).balance).to eq(40_00)
  end
end
