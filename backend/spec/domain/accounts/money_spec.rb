require "rails_helper"

RSpec.describe Accounts::Money do
  let(:positive_money) { described_class.new(100_00) }  # $100.00
  let(:zero_money) { described_class.new(0) }
  let(:negative_money) { described_class.new(-50_00) }

  describe "#initialize" do
    it "creates money with amount in cents" do
      money = described_class.new(100_00)

      expect(money.amount_cents).to eq(100_00)
    end

    it "defaults to USD currency" do
      money = described_class.new(100_00)

      expect(money.currency).to eq('USD')
    end

    it "accepts custom currency" do
      money = described_class.new(100_00, 'BRL')

      expect(money.currency).to eq('BRL')
    end

    it "accepts zero amount" do
      money = described_class.new(0)

      expect(money.amount_cents).to eq(0)
    end

    it "accepts negative amount" do
      money = described_class.new(-100_00)

      expect(money.amount_cents).to eq(-100_00)
    end
  end

  describe "#positive?" do
    it "returns true for positive amounts" do
      expect(positive_money.positive?).to be true
    end

    it "returns false for zero" do
      expect(zero_money.positive?).to be false
    end

    it "returns false for negative amounts" do
      expect(negative_money.positive?).to be false
    end
  end

  describe "#zero?" do
    it "returns true for zero amount" do
      expect(zero_money.zero?).to be true
    end

    it "returns false for positive amounts" do
      expect(positive_money.zero?).to be false
    end

    it "returns false for negative amounts" do
      expect(negative_money.zero?).to be false
    end
  end

  describe "#negative?" do
    it "returns true for negative amounts" do
      expect(negative_money.negative?).to be true
    end

    it "returns false for zero" do
      expect(zero_money.negative?).to be false
    end

    it "returns false for positive amounts" do
      expect(positive_money.negative?).to be false
    end
  end

  describe "#==" do
    context "when comparing with another Money object" do
      it "returns true for same amount and currency" do
        money1 = described_class.new(100_00, 'USD')
        money2 = described_class.new(100_00, 'USD')

        expect(money1 == money2).to be true
        expect(money1).to eq(money2)
      end

      it "returns false for different amounts" do
        money1 = described_class.new(100_00)
        money2 = described_class.new(50_00)

        expect(money1 == money2).to be false
        expect(money1).not_to eq(money2)
      end

      it "returns false for different currencies" do
        usd = described_class.new(100_00, 'USD')
        brl = described_class.new(100_00, 'BRL')

        expect(usd == brl).to be false
        expect(usd).not_to eq(brl)
      end
    end

    context "when comparing with non-Money objects" do
      it "returns false for nil" do
        expect(positive_money == nil).to be false
      end

      it "returns false for numbers" do
        expect(positive_money == 100_00).to be false
      end

      it "returns false for strings" do
        expect(positive_money == "100.00").to be false
      end

      it "returns false for other objects" do
        expect(positive_money == Object.new).to be false
      end
    end
  end

  describe "#to_s" do
    context "USD currency" do
      it "formats positive amount with dollar sign" do
        money = described_class.new(100_00, 'USD')

        expect(money.to_s).to eq("$100.0")
      end

      it "formats zero as currency" do
        money = described_class.new(0, 'USD')

        expect(money.to_s).to eq("$0.0")
      end

      it "formats negative amount with dollar sign" do
        money = described_class.new(-50_00, 'USD')

        expect(money.to_s).to eq("$-50.0")
      end

      it "handles cents correctly" do
        money = described_class.new(123_45, 'USD')

        expect(money.to_s).to eq("$123.45")
      end
    end

    context "BRL currency" do
      it "formats with R$ symbol" do
        money = described_class.new(100_00, 'BRL')

        expect(money.to_s).to eq("R$100.0")
      end
    end

    context "EUR currency" do
      it "formats with € symbol" do
        money = described_class.new(100_00, 'EUR')

        expect(money.to_s).to eq("€100.0")
      end
    end

    context "GBP currency" do
      it "formats with £ symbol" do
        money = described_class.new(100_00, 'GBP')

        expect(money.to_s).to eq("£100.0")
      end
    end

    context "unknown currency" do
      it "uses currency code as symbol" do
        money = described_class.new(100_00, 'JPY')

        expect(money.to_s).to eq("JPY100.0")
      end
    end
  end

  describe "value object behavior" do
    it "is immutable" do
      money = described_class.new(100_00)
      original_amount = money.amount_cents

      expect { money.amount_cents = 200_00 }.to raise_error(NoMethodError)
      expect(money.amount_cents).to eq(original_amount)
    end

    it "currency is immutable" do
      money = described_class.new(100_00, 'USD')

      expect { money.currency = 'BRL' }.to raise_error(NoMethodError)
    end

    it "can be used in arrays" do
      monies = [
        described_class.new(100_00),
        described_class.new(50_00),
        described_class.new(25_00)
      ]

      expect(monies.size).to eq(3)
    end

    it "can be compared in arrays" do
      money1 = described_class.new(100_00)
      money2 = described_class.new(100_00)

      expect([money1]).to include(money2)
    end
  end

  describe "multi-currency support" do
    it "allows creating money in different currencies" do
      usd = described_class.new(100_00, 'USD')
      brl = described_class.new(500_00, 'BRL')
      eur = described_class.new(85_00, 'EUR')

      expect(usd.currency).to eq('USD')
      expect(brl.currency).to eq('BRL')
      expect(eur.currency).to eq('EUR')
    end
  end
end