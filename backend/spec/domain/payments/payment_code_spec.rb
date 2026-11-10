require "rails_helper"

RSpec.describe Payments::PaymentCode do
  let(:code) { described_class.generate }

  describe ".generate" do
    it "builds a KNK1 code with 20 random chars and 4 check chars" do
      expect(code).to start_with("KNK1")
      expect(code.length).to eq(described_class::LENGTH)
      expect(code.length).to eq(28)
      expect(code[4..]).to match(/\A[0-9A-HJKMNP-TV-Z]+\z/)
    end

    it "produces a different code every time" do
      codes = Array.new(200) { described_class.generate }
      expect(codes.uniq.size).to eq(200)
    end
  end

  describe ".normalize!" do
    it "accepts a freshly generated code" do
      expect(described_class.normalize!(code)).to eq(code)
    end

    it "ignores case, spaces and dashes" do
      messy = " #{code.downcase.scan(/.{1,4}/).join('-')} \n"
      expect(described_class.normalize!(messy)).to eq(code)
    end

    it "maps the Crockford look-alikes O, I and L" do
      body = "0" * 10 + "1" * 10
      valid = "KNK1#{body}#{described_class.checksum(body)}"
      typed = valid.sub("0" * 10, "O" * 10).sub("1" * 10, "Il" * 5)

      expect(described_class.normalize!(typed)).to eq(valid)
    end

    it "rejects a code with a single changed character (typo)" do
      position = 10
      replacement = code[position] == "A" ? "B" : "A"
      typo = code.dup.tap { |c| c[position] = replacement }

      expect { described_class.normalize!(typo) }.to raise_error(described_class::InvalidCode)
    end

    it "rejects a made-up code with the right shape" do
      fake = "KNK1#{'A' * 20}ZZZZ"
      fake = "KNK1#{'A' * 20}YYYY" if described_class.checksum("A" * 20) == "ZZZZ"

      expect { described_class.normalize!(fake) }.to raise_error(described_class::InvalidCode)
    end

    it "rejects wrong length, wrong prefix and characters outside the alphabet" do
      [ nil, "", code[0..-2], "#{code}0", code.sub("KNK1", "KNK2"), code.sub(/.\z/, "U"), code.sub(/.\z/, "*") ].each do |input|
        expect { described_class.normalize!(input) }.to raise_error(described_class::InvalidCode), "accepted #{input.inspect}"
      end
    end
  end

  describe ".valid?" do
    it { expect(described_class.valid?(code)).to be(true) }
    it { expect(described_class.valid?("KNK1-not-a-code")).to be(false) }
  end
end
