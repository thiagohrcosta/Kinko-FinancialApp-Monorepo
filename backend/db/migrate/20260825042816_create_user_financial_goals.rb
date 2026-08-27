class CreateUserFinancialGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :user_financial_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :financial_goal, null: false, foreign_key: true
      t.integer :priority, null: false
      t.timestamps
    end
    add_index :user_financial_goals, [:user_id, :financial_goal_id], unique: true
  end
end
