class AccountRepository
  def self.load(account_id)
    record = Account.find_by!(uuid: account_id)

    entries = record.ledger_entries.order(:id).map do |entry|
      Accounts::LedgerEntry.new(
        amount_cents: entry.amount_cents,
        currency: entry.currency,
        reference: entry.reference
      )
    end

    Accounts::Account.new(record.uuid, entries)
  end

  def self.save(domain_account)
    record = Account.find_by!(uuid: domain_account.uuid)

    ActiveRecord::Base.transaction do
      domain_account.new_entries.each do |entry|
        record.ledger_entries.create!(
          amount_cents: entry.amount_cents,
          currency: entry.currency,
          entry_type: entry.amount_cents >= 0 ? "credit" : "debit",
          transaction_id: entry.reference
        )
      end
    end
  end
end
