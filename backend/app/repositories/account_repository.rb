class AccountRepository
  def self.load(account_id)
    record = Account.find(account_id)

    entries = record.ledger_entries.order(:id).map do |entry|
      Accounts::LedgerEntry.new(entry.amount_cents)
    end

    Accounts::Account.new(record.id, entries)
  end

  def self.save(domain_account)
    record = Account.find(domain_account.uuid)

    record.ledger_entries.destroy_all

    domain_account.entries.each do |entry|
      record.ledger_entries.create!(amount_cents: entry.amount_cents, currency: 'USD', entry_type: entry.amount_cents >= 0 ? 'credit' : 'debit')
    end
  end
end
