class AddCategorizationToLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    t.string :name, null: false, default: "uncategorized"
    t.string :icon, null: false, default: "uncategorized"
  end

  add_reference :ledger_entries, :spending_category, foreign_key: true, null: true
  add_column :ledger_entries, :raw_description, :string
  add_column :ledger_entries, :merchant_normalized, :string
  add_column :ledger_entries, :categorized_by, :string
  add_column :ledger_entries, :categorization_confidence, :float
end
