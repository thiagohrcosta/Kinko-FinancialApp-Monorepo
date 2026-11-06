# Database-level guarantees for the ledger, so that application bugs or
# concurrent requests cannot produce invalid or duplicated entries.
class HardenLedgerConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :ledger_entries, "amount_cents > 0", name: "ledger_entries_amount_positive"
    add_check_constraint :ledger_entries, "entry_type IN ('credit', 'debit')", name: "ledger_entries_entry_type_valid"

    # One leg per account per movement: replaying the same transaction_id
    # (e.g. a retried payment) cannot credit or debit an account twice.
    add_index :ledger_entries, [ :account_id, :transaction_id ],
              unique: true, where: "transaction_id IS NOT NULL",
              name: "index_ledger_entries_on_account_and_transaction_id"

    # An external reference (e.g. a Stripe PaymentIntent) is applied to an
    # account at most once.
    add_index :ledger_entries, [ :account_id, :reference ],
              unique: true, where: "reference IS NOT NULL",
              name: "index_ledger_entries_on_account_and_reference"

    change_column_null :accounts, :uuid, false
    add_index :accounts, :uuid, unique: true
  end
end
