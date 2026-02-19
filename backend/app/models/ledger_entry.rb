class LedgerEntry < ApplicationRecord
  belongs_to :account

  validates :amount_cents, presence: true
  validates :currency, presence: true
  validates :entry_type, presence: true

  enum :entry_type, {
    debit: "debit",
    credit: "credit"
  }
end
