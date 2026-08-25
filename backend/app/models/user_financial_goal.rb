class UserFinancialGoal < ApplicationRecord
  belongs_to :user
  belongs_to :financial_goal

  validates :priority, presence: true, inclusion: { in: 1..3 }
end
