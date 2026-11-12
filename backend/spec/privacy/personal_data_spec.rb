require "rails_helper"

RSpec.describe PersonalData do
  it "classifies every column of every application table" do
    expect(described_class.unclassified_columns).to be_empty, <<~MSG
      Add these columns to config/personal_data.yml (as `not_personal` or with a classification),
      then run `bin/rails privacy:inventory`:
        #{described_class.unclassified_columns.join("\n  ")}
    MSG
  end

  it "has no entries for columns that don't exist" do
    expect(described_class.stale_entries).to be_empty
  end

  it "uses only the categories, lawful bases, retention periods and erasure actions it defines" do
    expect(described_class.invalid_entries).to be_empty
  end

  it "keeps docs/privacy/data-inventory.md up to date" do
    expect(File.read(described_class::DOC_PATH)).to eq(described_class.doc_with_generated_section),
                                                     "Run `bin/rails privacy:inventory` in backend/ and commit the result"
  end

  it "marks government ID and credentials as sensitive" do
    sensitive = described_class.fields.select(&:sensitive?).map { |f| "#{f.table}.#{f.column}" }

    expect(sensitive).to include("users.document_number", "users.encrypted_password", "merchant_api_keys.token_digest",
                                 "webhook_endpoints.signing_secret")
  end

  it "keeps identity and financial records for the 5-year anti-money-laundering period" do
    retention = described_class.fields.to_h { |f| [ "#{f.table}.#{f.column}", f.retention ] }

    expect(retention.values_at("users.full_name", "users.document_number", "ledger_entries.amount_cents"))
      .to all(eq("aml_5_years"))
  end
end
