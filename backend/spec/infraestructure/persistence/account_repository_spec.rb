require "rails_helper"

RSpec.describe AccountRepository do
  let(:account_record) { create(:account_record) }

  describe ".load" do
    context "when account exists" do
      it "loads account from database" do
        account = described_class.load(account_record.id)

        expect(account).to be_a(Accounts::Account)
        expect(account.uuid).to eq(account_record.id)
      end

      it "loads account with empty entries" do
        account = described_class.load(account_record.id)

        expect(account.entries).to be_empty
      end

      context "with ledger entries" do
        before do
          create(:ledger_entry_record, account_record: account_record, amount_cents: 100_00)
          create(:ledger_entry_record, account_record: account_record, amount_cents: -50_00)
          create(:ledger_entry_record, account_record: account_record, amount_cents: 25_00)
        end

        it "loads all ledger entries" do
          account = described_class.load(account_record.id)

          expect(account.entries.size).to eq(3)
        end

        it "converts entries to domain objects" do
          account = described_class.load(account_record.id)

          expect(account.entries.first).to be_a(Accounts::LedgerEntry)
        end

        it "preserves entry amounts" do
          account = described_class.load(account_record.id)

          amounts = account.entries.map(&:amount_cents)
          expect(amounts).to contain_exactly(100_00, -50_00, 25_00)
        end

        it "calculates correct balance" do
          account = described_class.load(account_record.id)

          expect(account.balance).to eq(75_00) # 100 - 50 + 25
        end

        it "maintains entry order" do
          account = described_class.load(account_record.id)

          expect(account.entries.first.amount_cents).to eq(100_00)
          expect(account.entries.second.amount_cents).to eq(-50_00)
          expect(account.entries.third.amount_cents).to eq(25_00)
        end
      end
    end

    context "when account does not exist" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          described_class.load(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".save" do
    let(:domain_account) { Accounts::Account.new(account_record.id) }

    context "with new entries" do
      before do
        money_100 = Accounts::Money.new(100_00, 'USD')
        money_50 = Accounts::Money.new(50_00, 'USD')

        domain_account.credit!(money_100)
        domain_account.credit!(money_50)
      end

      it "persists entries to database" do
        expect {
          described_class.save(domain_account)
        }.to change { account_record.ledger_entries.count }.from(0).to(2)
      end

      it "saves correct amounts" do
        described_class.save(domain_account)

        amounts = account_record.ledger_entries.pluck(:amount_cents)
        expect(amounts).to contain_exactly(100_00, 50_00)
      end

      it "maintains entry order" do
        described_class.save(domain_account)

        entries = account_record.ledger_entries.order(:id)
        expect(entries.first.amount_cents).to eq(100_00)
        expect(entries.second.amount_cents).to eq(50_00)
      end
    end

    context "updating existing entries" do
      before do
        create(:ledger_entry_record, account_record: account_record, amount_cents: 100_00)
        create(:ledger_entry_record, account_record: account_record, amount_cents: 50_00)
      end

      it "destroys old entries before saving" do
        loaded_account = described_class.load(account_record.id)

        money = Accounts::Money.new(25_00, 'USD')
        loaded_account.credit!(money)

        expect {
          described_class.save(loaded_account)
        }.to change { account_record.ledger_entries.count }.from(2).to(3)
      end

      it "replaces all entries with current state" do
        loaded_account = described_class.load(account_record.id)
        money = Accounts::Money.new(75_00, 'USD')
        loaded_account.credit!(money)

        described_class.save(loaded_account)

        amounts = account_record.ledger_entries.pluck(:amount_cents)
        expect(amounts).to contain_exactly(100_00, 50_00, 75_00)
      end

      it "handles debit operations" do
        loaded_account = described_class.load(account_record.id)
        money = Accounts::Money.new(30_00, 'USD')
        loaded_account.debit!(money)

        described_class.save(loaded_account)

        amounts = account_record.ledger_entries.pluck(:amount_cents)
        expect(amounts).to include(-30_00)
      end
    end

    context "with empty entries" do
      it "removes all ledger entries" do
        create(:ledger_entry_record, account_record: account_record, amount_cents: 100_00)

        empty_account = Accounts::Account.new(account_record.id, [])

        expect {
          described_class.save(empty_account)
        }.to change { account_record.ledger_entries.count }.from(1).to(0)
      end
    end

    context "when account does not exist" do
      it "raises ActiveRecord::RecordNotFound" do
        fake_account = Accounts::Account.new(99999)

        expect {
          described_class.save(fake_account)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "round-trip persistence" do
    it "preserves account state through save and load" do
      domain_account = Accounts::Account.new(account_record.id)

      domain_account.credit!(Accounts::Money.new(100_00, 'USD'))
      domain_account.credit!(Accounts::Money.new(50_00, 'USD'))
      domain_account.debit!(Accounts::Money.new(25_00, 'USD'))

      original_balance = domain_account.balance
      original_entries_count = domain_account.entries.size

      described_class.save(domain_account)

      reloaded_account = described_class.load(account_record.id)

      expect(reloaded_account.balance).to eq(original_balance)
      expect(reloaded_account.entries.size).to eq(original_entries_count)
      expect(reloaded_account.balance).to eq(125_00) # 100 + 50 - 25
    end
  end
end