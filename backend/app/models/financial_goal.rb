class FinancialGoal < ApplicationRecord
  has_many :user_financial_goals, dependent: :destroy
  has_many :users, through: :user_financial_goals

  validates :key, presence: true, uniqueness: true
  validates :name_pt, :name_en, presence: true

  scope :active, -> { where(active: true).order(:position) }
end
