class CreateWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :webhook_events do |t|
      t.string :event_id
      t.string :status

      t.timestamps
    end
    add_index :webhook_events, :event_id, unique: true
  end
end
