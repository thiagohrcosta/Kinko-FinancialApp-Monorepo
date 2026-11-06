require 'rails_helper'

RSpec.describe "Api::V1::Transfers", type: :request do
  let(:alice) { create(:user, full_name: "Alice") }
  let(:bob) { create(:user, full_name: "Bob") }
  let(:alice_account) { alice.accounts.first }
  let(:bob_account) { bob.accounts.first }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: alice.id)}" } }

  before { create(:ledger_entry_record, account_record: alice_account, amount_cents: 100_00) }

  describe "POST /api/v1/transfers" do
    it "moves money and links both legs with the same transaction_id" do
      post "/api/v1/transfers",
           params: { destination_account_uuid: bob_account.uuid, amount_cents: 40_00, description: "Dinner" },
           headers: headers

      expect(response).to have_http_status(:ok)
      tx_id = JSON.parse(response.body)["transaction_id"]

      debit = alice_account.ledger_entries.find_by(entry_type: "debit")
      credit = bob_account.ledger_entries.find_by(entry_type: "credit")
      expect(debit.transaction_id).to eq(tx_id)
      expect(credit.transaction_id).to eq(tx_id)
      expect(debit.description).to eq("Dinner (to Bob)")
      expect(credit.description).to eq("Dinner (from Alice)")
    end

    it "rejects transfers above the balance" do
      post "/api/v1/transfers",
           params: { destination_account_uuid: bob_account.uuid, amount_cents: 500_00 },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Insufficient funds")
    end

    it "rejects transfers to the same account" do
      post "/api/v1/transfers",
           params: { destination_account_uuid: alice_account.uuid, amount_cents: 10_00 },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns not found for an unknown account" do
      post "/api/v1/transfers",
           params: { destination_account_uuid: SecureRandom.uuid, amount_cents: 10_00 },
           headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
