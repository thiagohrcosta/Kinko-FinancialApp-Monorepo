module Goals
  class SelectUserGoals
    MAX_GOALS = 3

    class TooManyGoalsError < StandardError; end
    class InvalidGoalKeyError < StandardError; end

    def call(user:, goal_keys:)
      keys = Array(goal_keys).uniq

      validate!(keys)

      goals = FinancialGoal.active.where(key: keys)

      ActiveRecord::Base.transaction do
        UserFinancialGoal.where(user: user).destroy_all
        goals.each_with_index do |goal, index|
          UserFinancialGoal.create!(user: user, financial_goal: goal, priority: index + 1)
        end
      end

      user.user_financial_goals.reload
    end

    private

    def validate!(keys)
      raise TooManyGoalsError, "Select at most #{MAX_GOALS} goals" if keys.size > MAX_GOALS
      raise InvalidGoalKeyError, "Invalid goal key" if FinancialGoal.active.where(key: keys).count != keys.size
    end
  end
end
