require "rails_helper"

RSpec.describe User, type: :model do
  it "builds a valid user from the factory" do
    expect(build(:user)).to be_valid
  end
end
