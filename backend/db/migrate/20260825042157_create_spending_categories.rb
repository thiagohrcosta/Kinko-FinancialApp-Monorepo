class CreateSpendingCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :spending_categories do |t|
      t.string :name, null: false
      t.string :icon

      t.timestamps
    end
  end
end
