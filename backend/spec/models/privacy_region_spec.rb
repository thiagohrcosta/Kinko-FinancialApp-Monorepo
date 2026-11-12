require "rails_helper"

RSpec.describe PrivacyRegion do
  def region(country, state = nil, on: Date.new(2026, 11, 12))
    described_class.for(country: country, state: state, on: on)
  end

  it "maps EEA countries, the UK and Switzerland to :eu" do
    expect([ region("DE"), region("FR"), region("NO"), region("GB"), region("CH") ]).to all(eq(:eu))
  end

  it "maps California to :us_ca" do
    expect(region("US", "CA")).to eq(:us_ca)
    expect(region("us", " ca ")).to eq(:us_ca)
  end

  it "maps US states with a privacy law in force to :us_state_law" do
    expect([ region("US", "VA"), region("US", "TX"), region("US", "IN") ]).to all(eq(:us_state_law))
  end

  it "waits for a state law's effective date" do
    expect(region("US", "IN", on: Date.new(2025, 12, 31))).to eq(:us_other)
    expect(region("US", "IN", on: Date.new(2026, 1, 1))).to eq(:us_state_law)
  end

  it "maps other US states to :us_other" do
    expect([ region("US", "NY"), region("US", "FL"), region("US", nil) ]).to all(eq(:us_other))
  end

  it "maps every other country to :other" do
    expect([ region("BR"), region("CA"), region("JP") ]).to all(eq(:other))
  end

  it "is :unknown without a country" do
    expect([ region(nil), region("") ]).to all(eq(:unknown))
  end

  it "only lists real codes" do
    expect(described_class::EUROPE - Country::CODES).to be_empty
    expect(described_class::US_STATE_LAWS.keys - Country::US_STATES).to be_empty
  end
end
