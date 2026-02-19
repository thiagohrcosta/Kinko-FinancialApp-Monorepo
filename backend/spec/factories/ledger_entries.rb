FactoryBot.define do
  factory :ledger_entry do
    account
    amount_cents { 100_00 }
    currency { "USD" }
    entry_type { "credit" }
    reference { nil }
  end

  factory :ledger_entry_record, class: 'LedgerEntry' do
    transient do
      account_record { nil }
    end

    account { account_record || association(:account_record) }
    amount_cents { 100_00 }
    currency { "USD" }
    entry_type { "credit" }
    reference { nil }
  end
end
