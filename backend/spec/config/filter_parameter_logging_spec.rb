require "rails_helper"

RSpec.describe "Parameter filtering in logs" do
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

  it "hides Stripe event data, which can carry billing details" do
    filtered = filter.filter("id" => "evt_1", "data" => { "object" => { "billing_details" => { "name" => "Jane" } } })

    expect(filtered).to eq("id" => "evt_1", "data" => "[FILTERED]")
  end

  it "keeps merchant metadata visible" do
    expect(filter.filter("metadata" => { "order" => "42" })).to eq("metadata" => { "order" => "42" })
  end

  it "hides the government ID and phone sent on sign-up" do
    filtered = filter.filter("document_number" => "123-45-6789", "phone_number" => "+1 555 0100")

    expect(filtered).to eq("document_number" => "[FILTERED]", "phone_number" => "[FILTERED]")
  end

  it "hides passwords, tokens and emails" do
    filtered = filter.filter("password" => "x", "token" => "y", "email" => "a@b.c", "full_name" => "Jane")

    expect(filtered).to eq("password" => "[FILTERED]", "token" => "[FILTERED]", "email" => "[FILTERED]", "full_name" => "Jane")
  end
end
