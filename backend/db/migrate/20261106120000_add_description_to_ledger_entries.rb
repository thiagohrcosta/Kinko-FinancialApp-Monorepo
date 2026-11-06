class AddDescriptionToLedgerEntries < ActiveRecord::Migration[8.0]
  UUID_REGEX = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$".freeze

  def up
    add_column :ledger_entries, :description, :string

    # Até aqui o domínio gravava em `reference` a descrição OU o transaction_id.
    # Separa os dois: UUIDs viram transaction_id, o resto vira description.
    execute <<~SQL
      UPDATE ledger_entries
         SET transaction_id = COALESCE(transaction_id, reference),
             reference = NULL
       WHERE reference ~* '#{UUID_REGEX}'
    SQL

    execute <<~SQL
      UPDATE ledger_entries
         SET description = reference,
             reference = NULL
       WHERE reference IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL
      UPDATE ledger_entries
         SET reference = COALESCE(description, transaction_id)
       WHERE reference IS NULL
    SQL

    remove_column :ledger_entries, :description
  end
end
