class Account < ApplicationRecord
  class InsufficientFunds < StandardError; end

  belongs_to :user
  has_many :ledger_entries, dependent: :destroy

  validates :uuid, presence: true, uniqueness: true
  validates :status, presence: true

  before_validation :generate_uuid, on: :create

  def balance
    ledger_entries.sum(:amount_cents)
  end

  def credit!(money, reference: nil)
    create_entry!(money, "credit", reference)
  end

  def debit!(money, reference: nil)
    raise InsufficientFunds if insufficient?(money)

    create_entry!(money, "debit", reference)
  end

  def insufficient?(money)
    balance_cents < money.amount_cents
  end

  private

  def create_entry!(money, type, reference)
    ledger_entries.create!(
      amount_cents: type == "credit" ? money.amount_cents : -money.amount_cents,
      currency: money.currency,
      entry_type: type,
      reference: reference
    )
  end

  def balance_cents
    ledger_entries.sum(:amount_cents)
  end

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

end
