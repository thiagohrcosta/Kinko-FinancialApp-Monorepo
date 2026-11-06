class AddDescriptionToLedgerEntries < ActiveRecord::Migration[8.0]
  UUID_REGEX = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$".freeze

  def up
    add_column :ledger_entries, :description, :string

    # Until now the domain stored either the description OR the transaction id in `reference`.
    # 1) UUIDs become transaction_id — only when they don't clash with an existing one.
    execute <<~SQL
      UPDATE ledger_entries
         SET transaction_id = reference,
             reference = NULL
       WHERE reference ~* '#{UUID_REGEX}'
         AND (transaction_id IS NULL OR transaction_id = reference)
    SQL

    # 2) Free text becomes description.
    execute <<~SQL
      UPDATE ledger_entries
         SET description = reference,
             reference = NULL
       WHERE reference IS NOT NULL
         AND reference !~* '#{UUID_REGEX}'
    SQL
  end

  def down
    # The old schema only had `reference`, which the domain used for the description
    # (or, without one, the transaction id). Restore with that same priority.
    execute <<~SQL
      UPDATE ledger_entries
         SET reference = COALESCE(description, reference, transaction_id)
    SQL

    remove_column :ledger_entries, :description
  end
end
