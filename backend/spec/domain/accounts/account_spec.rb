require "rails_helper"

RSpec.describe Accounts::Account do
  let(:uuid) { SecureRandom.uuid }
  let(:account) { described_class.new(uuid) }
  let(:money_100) { Accounts::Money.new(100_00) } # R$ 100,00
  let(:money_50) { Accounts::Money.new(50_00) }   # R$ 50,00
  let(:money_200) { Accounts::Money.new(200_00) } # R$ 200,00
  let(:money_zero) { Accounts::Money.new(0) }
  let(:money_negative) { Accounts::Money.new(-10_00) }

  describe "#initialize" do
    it "creates account with uuid" do
      expect(account.uuid).to eq(uuid)
    end

    it "creates account with empty entries by default" do
      expect(account.entries).to be_empty
    end

    it "creates account with provided entries" do
      entries = [Accounts::LedgerEntry.new(amount_cents: 100_00, currency: "USD")]
      account_with_entries = described_class.new(uuid, entries)

      expect(account_with_entries.entries).to eq(entries)
      expect(account_with_entries.entries.size).to eq(1)
    end
  end

  describe "#balance" do
    context "with no entries" do
      it "returns zero" do
        expect(account.balance).to eq(0)
      end
    end

    context "with positive entries" do
      before do
        account.credit!(money_100)
        account.credit!(money_50)
      end

      it "returns sum of all entries" do
        expect(account.balance).to eq(150_00)
      end
    end

    context "with mixed entries" do
      before do
        account.credit!(money_100)  # +100
        account.debit!(money_50)    # -50
      end

      it "returns correct balance" do
        expect(account.balance).to eq(50_00)
      end
    end

    context "with multiple debits and credits" do
      before do
        account.credit!(money_100)  # +100
        account.credit!(money_200)  # +200
        account.debit!(money_50)    # -50
        account.debit!(money_100)   # -100
      end

      it "calculates balance correctly" do
        expect(account.balance).to eq(150_00) # 100 + 200 - 50 - 100
      end
    end
  end

  describe "#credit!" do
    context "with positive amount" do
      it "adds entry to account" do
        expect {
          account.credit!(money_100)
        }.to change { account.entries.size }.by(1)
      end

      it "increases balance" do
        expect {
          account.credit!(money_100)
        }.to change { account.balance }.by(100_00)
      end

      it "creates entry with correct amount" do
        account.credit!(money_100)

        expect(account.entries.last.amount_cents).to eq(100_00)
      end

      it "allows multiple credits" do
        account.credit!(money_100)
        account.credit!(money_50)

        expect(account.entries.size).to eq(2)
        expect(account.balance).to eq(150_00)
      end
    end

    context "with zero amount" do
      it "raises InvalidAmount" do
        expect {
          account.credit!(money_zero)
        }.to raise_error(Accounts::InvalidAmount)
      end

      it "does not add entry" do
        expect {
          account.credit!(money_zero) rescue nil
        }.not_to change { account.entries.size }
      end
    end

    context "with negative amount" do
      it "raises InvalidAmount" do
        expect {
          account.credit!(money_negative)
        }.to raise_error(Accounts::InvalidAmount)
      end

      it "does not modify balance" do
        expect {
          account.credit!(money_negative) rescue nil
        }.not_to change { account.balance }
      end
    end
  end

  describe "#debit!" do
    context "with sufficient balance" do
      before { account.credit!(money_200) }

      it "adds negative entry to account" do
        expect {
          account.debit!(money_100)
        }.to change { account.entries.size }.by(1)
      end

      it "decreases balance" do
        expect {
          account.debit!(money_100)
        }.to change { account.balance }.by(-100_00)
      end

      it "creates entry with negative amount" do
        account.debit!(money_100)

        expect(account.entries.last.amount_cents).to eq(-100_00)
      end

      it "allows multiple debits" do
        account.debit!(money_50)
        account.debit!(money_50)

        expect(account.entries.size).to eq(3) # 1 credit + 2 debits
        expect(account.balance).to eq(100_00)
      end
    end

    context "with insufficient balance" do
      before { account.credit!(money_50) }

      it "raises InsufficientFunds" do
        expect {
          account.debit!(money_100)
        }.to raise_error(Accounts::InsufficientFunds)
      end

      it "does not add entry" do
        expect {
          account.debit!(money_100) rescue nil
        }.not_to change { account.entries.size }
      end

      it "does not modify balance" do
        expect {
          account.debit!(money_100) rescue nil
        }.not_to change { account.balance }
      end
    end

    context "with zero balance" do
      it "raises InsufficientFunds" do
        expect {
          account.debit!(money_100)
        }.to raise_error(Accounts::InsufficientFunds)
      end
    end

    context "with exact balance" do
      before { account.credit!(money_100) }

      it "allows debit of exact amount" do
        expect {
          account.debit!(money_100)
        }.not_to raise_error
      end

      it "results in zero balance" do
        account.debit!(money_100)

        expect(account.balance).to eq(0)
      end
    end

    context "with zero amount" do
      before { account.credit!(money_100) }

      it "raises InvalidAmount" do
        expect {
          account.debit!(money_zero)
        }.to raise_error(Accounts::InvalidAmount)
      end
    end

    context "with negative amount" do
      before { account.credit!(money_100) }

      it "raises InvalidAmount" do
        expect {
          account.debit!(money_negative)
        }.to raise_error(Accounts::InvalidAmount)
      end
    end
  end

  describe "complex operations" do
    it "handles sequence of credits and debits correctly" do
      account.credit!(money_100)  # Balance: 100
      account.credit!(money_200)  # Balance: 300
      account.debit!(money_50)    # Balance: 250
      account.credit!(money_100)  # Balance: 350
      account.debit!(money_100)   # Balance: 250

      expect(account.balance).to eq(250_00)
      expect(account.entries.size).to eq(5)
    end

    it "prevents overdraft at any point" do
      account.credit!(money_100)
      account.debit!(money_50)

      expect {
        account.debit!(money_100) # Would overdraft
      }.to raise_error(Accounts::InsufficientFunds)

      expect(account.balance).to eq(50_00)
    end
  end

  describe "immutability of entries" do
    it "entries array is mutable within the aggregate" do
      account.credit!(money_100)
      first_entry_count = account.entries.size

      account.credit!(money_50)

      expect(account.entries.size).to eq(first_entry_count + 1)
    end
  end
end