class AccountRepository
  def self.load(account_id)
    record = Account.find_by!(uuid: account_id)

    entries = record.ledger_entries.order(:id).map do |entry|
      Accounts::LedgerEntry.new(
        amount_cents: entry.amount_cents,
        currency: entry.currency,
        entry_type: entry.entry_type.to_sym,
        description: entry.description,
        transaction_id: entry.transaction_id,
        reference: entry.reference
      )
    end

    Accounts::Account.new(record.uuid, entries)
  end

  # Runs a balance-changing operation atomically:
  #   1. locks the account rows (SELECT ... FOR UPDATE), always in id order
  #      so two operations on the same pair of accounts cannot deadlock;
  #   2. loads the domain accounts only after the lock, so the balance seen
  #      by `debit!` cannot be changed by a concurrent request;
  #   3. yields them, then persists every new entry in the same transaction.
  #
  # Usage:
  #   AccountRepository.with_locked(from_uuid, to_uuid) do |from, to|
  #     from.debit!(money)
  #     to.credit!(money)
  #   end
  def self.with_locked(*uuids)
    uuids = uuids.flatten

    ActiveRecord::Base.transaction do
      locked = Account.where(uuid: uuids.uniq).order(:id).lock.to_a
      missing = uuids.uniq - locked.map(&:uuid)
      raise ActiveRecord::RecordNotFound, "Account not found: #{missing.join(', ')}" if missing.any?

      accounts = uuids.map { |uuid| load(uuid) }
      result = yield(*accounts)
      accounts.each { |account| save(account) }
      result
    end
  end

  # The ledger is append-only: only new entries are written; existing
  # entries are never updated or deleted.
  def self.save(domain_account)
    record = Account.find_by!(uuid: domain_account.uuid)

    ActiveRecord::Base.transaction do
      domain_account.new_entries.each do |entry|
        record.ledger_entries.create!(
          amount_cents: entry.amount_cents,
          currency: entry.currency,
          entry_type: entry.entry_type.to_s,
          description: entry.description,
          transaction_id: entry.transaction_id,
          reference: entry.reference
        )
      end
    end
  end
end
