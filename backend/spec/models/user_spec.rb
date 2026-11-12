require "rails_helper"

RSpec.describe User, type: :model do
  # Subject reutilizável
  subject(:user) { build(:user) }

  describe "validations" do
    # Testa tudo de uma vez
    it { is_expected.to be_valid }

    # Usando shoulda-matchers (muito mais limpo!)
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_presence_of(:address_street) }
    it { is_expected.to validate_presence_of(:address_number) }
    it { is_expected.to validate_presence_of(:address_city) }
    it { is_expected.to validate_presence_of(:address_state) }
    it { is_expected.to validate_presence_of(:address_neighborhood) }
    it { is_expected.to validate_presence_of(:address_zip_code) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_length_of(:password).is_at_least(6) }
    it { is_expected.to validate_presence_of(:address_country).on(:create) }
  end

  describe "country and US state" do
    it "normalizes the country code" do
      expect(build(:user, address_country: " us ", address_state: "CA").address_country).to eq("US")
    end

    it "rejects codes that aren't ISO 3166-1 alpha-2" do
      user = build(:user, address_country: "XX")

      expect(user).not_to be_valid
      expect(user.errors[:address_country]).to include("is not a valid country")
    end

    it "requires a US state code for US addresses" do
      user = build(:user, address_country: "US", address_state: "California")

      expect(user).not_to be_valid
      expect(user.errors[:address_state]).to include("must be a US state code, e.g. CA")
    end

    it "upcases US state codes" do
      user = build(:user, address_country: "US", address_state: " ca ")

      expect(user).to be_valid
      expect(user.address_state).to eq("CA")
    end

    it "leaves other countries' states alone" do
      expect(build(:user, address_country: "DE", address_state: "Bayern")).to be_valid
    end

    it "lets users created before the country was asked be updated" do
      user = create(:user)
      user.update_column(:address_country, nil)

      expect(user.update(full_name: "Renamed")).to be(true)
    end
  end

  describe "#privacy_region" do
    it "comes from the country and state" do
      expect(build(:user, :californian).privacy_region).to eq(:us_ca)
      expect(build(:user, address_country: "DE", address_state: "Bayern").privacy_region).to eq(:eu)
      expect(build(:user).privacy_region).to eq(:other)
      expect(build(:user, address_country: nil).privacy_region).to eq(:unknown)
    end
  end

  describe "legacy users without neighborhood" do
    it "can still be updated (neighborhood is only required on sign-up)" do
      user = create(:user)
      user.update_column(:address_neighborhood, nil)

      expect(user.update(full_name: "Renamed")).to be(true)
    end
  end


  # describe "associations" do
  #   # it { is_expected.to have_many(:xxxx) }
  #   # it { is_expected.to belong_to(:xxxx) }
  # end

  # Custom method tests
  # describe "#full_name" do
  # end
end
