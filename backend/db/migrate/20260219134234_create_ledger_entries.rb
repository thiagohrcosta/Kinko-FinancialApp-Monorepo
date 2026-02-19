class CreateLedgerEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.string :entry_type, null: false
      t.string :reference

      t.timestamps
    end
  end
end
