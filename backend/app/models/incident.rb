require "csv"

# Tools for responding to a security incident (docs/security/incident-response.md).
# Used from the rake tasks in lib/tasks/incident.rake.
module Incident
  # Where personal data about a user can be found, per table. Each lambda
  # returns the user ids whose data is in that table for the given rows.
  SOURCES = {
    "users" => ->(rows) { rows.call(User).pluck(:id) },
    "accounts" => ->(rows) { rows.call(Account).pluck(:user_id) },
    "ledger_entries" => ->(rows) { Account.where(id: rows.call(LedgerEntry).select(:account_id)).pluck(:user_id) },
    "payment_requests" => lambda { |rows|
      charges = rows.call(PaymentRequest)
      Account.where(id: charges.select(:merchant_account_id)).or(Account.where(id: charges.select(:payer_account_id))).pluck(:user_id)
    },
    "merchant_api_keys" => ->(rows) { rows.call(MerchantApiKey).pluck(:user_id) },
    "webhook_endpoints" => ->(rows) { rows.call(WebhookEndpoint).pluck(:user_id) },
    # The merchant that received it, and the payer named in the payload.
    "webhook_deliveries" => lambda { |rows|
      deliveries = rows.call(WebhookDelivery)
      merchants = WebhookEndpoint.where(id: deliveries.select(:webhook_endpoint_id)).pluck(:user_id)
      payer_accounts = deliveries.pluck(Arel.sql("payload -> 'data' -> 'payer' ->> 'account_uuid'")).compact
      merchants + Account.where(uuid: payer_accounts).pluck(:user_id)
    }
  }.freeze

  # How the data was exposed:
  #   :snapshot  everything that existed at the end of the window (a database
  #              dump, a leaked backup, read access to a table)
  #   :activity  only rows created or changed during the window (data that
  #              went through a leaking log, request or job)
  EXPOSURES = %i[snapshot activity].freeze

  module_function

  def affected_users(from:, to:, tables:, exposure: :snapshot)
    unknown = tables - SOURCES.keys
    raise ArgumentError, "Unknown tables: #{unknown.join(', ')} (known: #{SOURCES.keys.join(', ')})" if unknown.any?
    raise ArgumentError, "exposure must be one of #{EXPOSURES.join(', ')}" unless EXPOSURES.include?(exposure)

    rows = lambda do |model|
      if exposure == :snapshot
        model.where(created_at: ..to)
      else
        model.where(created_at: from..to).or(model.where(updated_at: from..to))
      end
    end

    ids = tables.flat_map { |table| SOURCES.fetch(table).call(rows) }.uniq
    User.where(id: ids).order(:id)
  end

  CSV_COLUMNS = %w[id email full_name user_type address_state address_country privacy_region].freeze

  # One row per affected user, with what's needed to decide who must be
  # notified (country and state decide the law; see docs/security/incident-response.md).
  def to_csv(users)
    CSV.generate do |csv|
      csv << CSV_COLUMNS
      users.each do |user|
        csv << [
          user.id, user.email, user.full_name, user.user_type, user.address_state,
          user.try(:address_country), user.try(:privacy_region) || "unknown"
        ]
      end
    end
  end

  # Containment. Each returns how many records it changed.

  def revoke_all_api_keys!
    MerchantApiKey.active.find_each.count(&:revoke!)
  end

  def disable_all_webhooks!
    WebhookEndpoint.where(active: true).update_all(active: false, updated_at: Time.current)
  end

  def rotate_all_webhook_secrets!
    WebhookEndpoint.find_each.count(&:rotate_secret!)
  end
end
