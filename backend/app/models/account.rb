class Account < ApplicationRecord
  belongs_to :user
  has_many :ledger_entries, dependent: :restrict_with_exception

  validates :uuid, presence: true, uniqueness: true
  validates :status, presence: true

  before_validation :generate_uuid, on: :create

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

end
