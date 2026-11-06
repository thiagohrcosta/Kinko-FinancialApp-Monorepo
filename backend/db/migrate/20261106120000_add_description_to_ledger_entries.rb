class AddDescriptionToLedgerEntries < ActiveRecord::Migration[8.0]
  UUID_REGEX = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$".freeze

  def up
    add_column :ledger_entries, :description, :string

    # Até aqui o domínio gravava em `reference` a descrição OU o transaction_id.
    # 1) UUIDs viram transaction_id — só quando não conflitam com um já existente.
    execute <<~SQL
      UPDATE ledger_entries
         SET transaction_id = reference,
             reference = NULL
       WHERE reference ~* '#{UUID_REGEX}'
         AND (transaction_id IS NULL OR transaction_id = reference)
    SQL

    # 2) Texto livre vira description.
    execute <<~SQL
      UPDATE ledger_entries
         SET description = reference,
             reference = NULL
       WHERE reference IS NOT NULL
         AND reference !~* '#{UUID_REGEX}'
    SQL
  end

  def down
    # O schema antigo só tinha `reference`, que o domínio usava para a descrição
    # (ou, sem ela, o transaction_id). Restaura nessa mesma prioridade.
    execute <<~SQL
      UPDATE ledger_entries
         SET reference = COALESCE(description, reference, transaction_id)
    SQL

    remove_column :ledger_entries, :description
  end
end
