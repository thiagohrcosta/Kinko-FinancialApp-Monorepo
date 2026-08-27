class CreateRecurringChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_changes do |t|
      t.references :account, null: false, foreign_key: true
      t.string :merchant_normalized, null: false
      t.bigint :average_amount_cents
      t.string :frequency
      t.date :first_detected_at
      t.date :last_seen_at
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
