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
  end


  # describe "associations" do
  #   # it { is_expected.to have_many(:xxxx) }
  #   # it { is_expected.to belong_to(:xxxx) }
  # end

  # Custom method tests
  # describe "#full_name" do
  # end
end