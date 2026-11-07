# Payment gateway: merchants (business users) integrate with Kinko through
# Kinko API keys, create payment requests, and are notified by webhooks.
class CreatePaymentGateway < ActiveRecord::Migration[8.1]
  def change
    # Only the SHA-256 digest of a key is stored; the plain key is shown once.
    create_table :merchant_api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :last4, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :merchant_api_keys, :token_digest, unique: true

    create_table :payment_requests do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      # The copy-and-paste payment code (also encoded in the QR code).
      t.string :code, null: false
      t.references :merchant_account, null: false, foreign_key: { to_table: :accounts }
      t.references :merchant_api_key, foreign_key: true
      t.bigint :amount_cents, null: false
      # Kinko fee charged to the merchant. Always 0 for now; kept so fees can
      # be enabled later without a data migration.
      t.bigint :fee_cents, null: false, default: 0
      t.string :currency, null: false
      t.string :description, null: false
      t.string :external_reference
      t.string :idempotency_key
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.datetime :paid_at
      t.datetime :canceled_at
      t.references :payer_account, foreign_key: { to_table: :accounts }
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :payment_requests, :public_id, unique: true
    add_index :payment_requests, :code, unique: true
    add_index :payment_requests, [ :merchant_account_id, :idempotency_key ],
              unique: true, where: "idempotency_key IS NOT NULL",
              name: "index_payment_requests_on_merchant_and_idempotency_key"
    add_index :payment_requests, [ :status, :expires_at ]
    add_check_constraint :payment_requests, "amount_cents > 0", name: "payment_requests_amount_positive"
    add_check_constraint :payment_requests, "fee_cents >= 0 AND fee_cents <= amount_cents", name: "payment_requests_fee_valid"
    add_check_constraint :payment_requests, "status IN ('pending', 'paid', 'canceled', 'expired')", name: "payment_requests_status_valid"
    add_check_constraint :payment_requests, "status <> 'paid' OR (payer_account_id IS NOT NULL AND paid_at IS NOT NULL)",
                         name: "payment_requests_paid_has_payer"

    create_table :webhook_endpoints do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :url, null: false
      t.string :signing_secret, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    # Outbox: a delivery row is written in the same transaction as the event,
    # then sent (and retried) by WebhookDeliveryJob.
    create_table :webhook_deliveries do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.integer :last_response_code
      t.string :last_error
      t.datetime :delivered_at
      t.timestamps
    end
    add_index :webhook_deliveries, :public_id, unique: true
    add_check_constraint :webhook_deliveries, "status IN ('pending', 'succeeded', 'failed')", name: "webhook_deliveries_status_valid"
  end
end
