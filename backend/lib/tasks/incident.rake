# Incident response tools. See docs/security/incident-response.md.
namespace :incident do
  desc "List users whose data is in the given tables. FROM, TO (ISO 8601), TABLES (comma-separated), " \
       "EXPOSURE=snapshot|activity (default snapshot). Writes CSV to stdout."
  task affected_users: :environment do
    from = Time.iso8601(ENV.fetch("FROM"))
    to = Time.iso8601(ENV.fetch("TO"))
    tables = ENV.fetch("TABLES").split(",").map(&:strip)
    exposure = ENV.fetch("EXPOSURE", "snapshot").to_sym

    users = Incident.affected_users(from: from, to: to, tables: tables, exposure: exposure)
    $stdout.write(Incident.to_csv(users))
    warn "#{users.count} affected users (#{exposure}, #{tables.join(', ')}, #{from.iso8601}..#{to.iso8601})"
  end

  desc "Revoke every active merchant API key. APPLY=1 to do it."
  task revoke_api_keys: :environment do
    next warn("Dry run: #{MerchantApiKey.active.count} active API keys would be revoked. APPLY=1 to do it.") unless ENV["APPLY"] == "1"

    warn "Revoked #{Incident.revoke_all_api_keys!} API keys."
  end

  desc "Stop all merchant webhook deliveries. APPLY=1 to do it."
  task disable_webhooks: :environment do
    next warn("Dry run: #{WebhookEndpoint.where(active: true).count} webhook endpoints would be disabled. APPLY=1 to do it.") unless ENV["APPLY"] == "1"

    warn "Disabled #{Incident.disable_all_webhooks!} webhook endpoints."
  end

  desc "Give every webhook endpoint a new signing secret. APPLY=1 to do it."
  task rotate_webhook_secrets: :environment do
    next warn("Dry run: #{WebhookEndpoint.count} webhook secrets would be rotated. APPLY=1 to do it.") unless ENV["APPLY"] == "1"

    warn "Rotated #{Incident.rotate_all_webhook_secrets!} webhook secrets."
  end
end
