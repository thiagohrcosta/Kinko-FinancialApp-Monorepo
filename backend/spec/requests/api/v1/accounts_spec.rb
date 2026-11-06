require 'rails_helper'

RSpec.describe "Api::V1::Accounts", type: :request do
  let(:user) { create(:user, full_name: "Alice") }
  let(:account) { user.accounts.first }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "GET /api/v1/accounts/balance" do
    it "derives balance, income and expenses from the ledger" do
      create(:ledger_entry_record, account_record: account, amount_cents: 100_00, entry_type: "credit")
      create(:ledger_entry_record, account_record: account, amount_cents: 30_00, entry_type: "debit")

      get "/api/v1/accounts/balance", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["balance"]).to eq("70.0")
      expect(json["income"]).to eq(100.0)
      expect(json["expenses"]).to eq(30.0)
    end

    it "requires authentication" do
      get "/api/v1/accounts/balance"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/accounts/transactions" do
    let(:bob) { create(:user, full_name: "Bob") }

    it "returns the stored description" do
      create(:ledger_entry_record, account_record: account, amount_cents: 12_00, description: "Coffee shop")

      get "/api/v1/accounts/transactions", headers: headers

      expect(JSON.parse(response.body).first["description"]).to eq("Coffee shop")
    end

    it "falls back to Deposit/Withdrawal when there is no description or counterparty" do
      create(:ledger_entry_record, account_record: account, amount_cents: 50_00, entry_type: "credit")
      create(:ledger_entry_record, account_record: account, amount_cents: 10_00, entry_type: "debit")

      get "/api/v1/accounts/transactions", headers: headers

      descriptions = JSON.parse(response.body).map { |t| t["description"] }
      expect(descriptions).to contain_exactly("Deposit", "Withdrawal")
    end

    it "resolves the counterparty of a transfer through transaction_id" do
      create(:ledger_entry_record, account_record: account, amount_cents: 100_00)
      Transfers::TransferService.new(account_repository: AccountRepository).call(
        from_uuid: account.uuid, to_uuid: bob.accounts.first.uuid, money: Accounts::Money.new(25_00)
      )

      get "/api/v1/accounts/transactions", headers: headers

      transfer = JSON.parse(response.body).find { |t| t["entry_type"] == "debit" }
      expect(transfer["description"]).to eq("Transfer to Bob")
      expect(transfer["counterparty_name"]).to eq("Bob")
    end

    it "only returns entries of the requested month" do
      create(:ledger_entry_record, account_record: account, amount_cents: 1_00, created_at: Time.zone.parse("2026-01-31 23:00"))
      create(:ledger_entry_record, account_record: account, amount_cents: 2_00, created_at: Time.zone.parse("2026-02-01 00:30"))

      get "/api/v1/accounts/transactions", params: { month: "2026-01" }, headers: headers

      expect(JSON.parse(response.body).map { |t| t["amount_cents"] }).to eq([1_00])
    end

    it "rejects an invalid month" do
      get "/api/v1/accounts/transactions", params: { month: "2026-13" }, headers: headers

      expect(response).to have_http_status(:bad_request)
    end
  end
end
