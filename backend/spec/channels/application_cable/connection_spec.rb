require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }

  it "connects with a valid JWT" do
    connect "/cable", params: { token: JsonWebToken.encode(user_id: user.id) }

    expect(connection.current_user).to eq(user)
  end

  it "rejects a missing token" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects an invalid token" do
    expect { connect "/cable", params: { token: "not-a-jwt" } }.to have_rejected_connection
  end

  it "rejects an expired token" do
    token = JsonWebToken.encode({ user_id: user.id }, 1.minute.ago)

    expect { connect "/cable", params: { token: token } }.to have_rejected_connection
  end

  it "rejects a token for a user that no longer exists" do
    token = JsonWebToken.encode(user_id: user.id)
    user.destroy!

    expect { connect "/cable", params: { token: token } }.to have_rejected_connection
  end
end
