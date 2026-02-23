class AddReferenceToLedgerEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :ledger_entries, :transaction_id, :string, null: true
    add_index :ledger_entries, :transaction_id
  end
end
