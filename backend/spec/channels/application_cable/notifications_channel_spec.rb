require "rails_helper"

RSpec.describe ApplicationCable::NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  it "streams the connected user's notifications only" do
    stub_connection current_user: user
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("notifications:user:#{user.id}")
  end
end
