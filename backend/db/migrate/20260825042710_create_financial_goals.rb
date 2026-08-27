class CreateFinancialGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_goals do |t|
      t.string :key, null: false
      t.string :name_pt, null: false
      t.string :name_en, null: false
      t.text :description
      t.string :icon
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :financial_goals, :key, unique: true
  end
end
