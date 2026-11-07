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

    it "returns bad request when a parameter is missing" do
      post "/api/v1/transfers", params: { amount_cents: 10_00 }, headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to eq("Missing parameter: destination_account_uuid")
    end

    it "does not leak internal error details" do
      allow_any_instance_of(Transfers::TransferService).to receive(:call)
        .and_raise(StandardError, "PG::ConnectionBad: secret host db-internal:5432")

      post "/api/v1/transfers",
           params: { destination_account_uuid: bob_account.uuid, amount_cents: 10_00 },
           headers: headers

      expect(response).to have_http_status(:internal_server_error)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Internal error")
      expect(body["request_id"]).to be_present
      expect(response.body).not_to include("db-internal")
    end

    it "returns not found for an unknown account" do
      post "/api/v1/transfers",
           params: { destination_account_uuid: SecureRandom.uuid, amount_cents: 10_00 },
           headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
