module Goals
  class ListAvailableGoals
    def call(locale: :pt)
      FinancialGoal.active.map do |goal|
        {
          key: goal.key,
          name: locale == :en ? goal.name_en : goal.name_pt,
          description: goal.description,
          icon: goal.icon
        }
      end
    end
  end
end
