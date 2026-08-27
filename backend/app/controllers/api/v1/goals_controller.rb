module Api
  module V1
    class GoalsController < ApplicationController
      include Authenticatable

      # GET /api/v1/goals
      def index
        goals = Goals::ListAvailableGoals.new.call(locale: locale_param)
        render json: goals
      end

      # GET /api/v1/goals/mine
      def mine
        selected = current_user.financial_goals
                                .joins(:user_financial_goals)
                                .order("user_financial_goals.priority")
        render json: selected.map { |g| { key: g.key, name: g.name_pt } }
      end

      # PATCH /api/v1/goals
      def update
        Goals::SelectUserGoals.new.call(user: current_user, goal_keys: params[:goal_keys])
        render json: { status: "ok" }
      rescue Goals::SelectUserGoals::TooManyGoalsError,
             Goals::SelectUserGoals::InvalidGoalKeyError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def locale_param
        params[:locale] == "en" ? :en : :pt
      end
    end
  end
end
