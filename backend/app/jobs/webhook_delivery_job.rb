require "net/http"

# Sends one webhook to a merchant and retries with backoff until it gets a
# 2xx. Merchants verify the Kinko-Signature header (see Webhooks::Signature).
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  # Waits between attempts: about 45 hours in total, so a merchant whose
  # server is down for a day still gets every event (#48).
  RETRY_SCHEDULE = [ 1.minute, 5.minutes, 30.minutes, 2.hours, 6.hours, 12.hours, 24.hours ].freeze
  MAX_ATTEMPTS = RETRY_SCHEDULE.size + 1
  TIMEOUT = 5 # seconds

  class DeliveryFailed < StandardError; end

  retry_on DeliveryFailed, attempts: MAX_ATTEMPTS,
                           wait: ->(executions) { RETRY_SCHEDULE.fetch(executions - 1, RETRY_SCHEDULE.last) } do |job, _error|
    WebhookDelivery.find_by(id: job.arguments.first)&.update!(status: "failed")
  end

  def perform(delivery_id)
    delivery = WebhookDelivery.includes(:webhook_endpoint).find_by(id: delivery_id)
    return if delivery.nil? || delivery.status == "succeeded"

    endpoint = delivery.webhook_endpoint
    return delivery.update!(status: "failed", last_error: "Endpoint disabled") unless endpoint.active?

    body = delivery.payload.to_json
    delivery.increment!(:attempts)

    # Re-checked at send time: DNS may now point somewhere private.
    target = WebhookEndpoint.public_target(endpoint.url)
    unless target
      delivery.update!(last_error: "Unsafe URL")
      raise DeliveryFailed, "Unsafe URL"
    end

    response = post(target, endpoint, delivery, body)
    delivery.update!(last_response_code: response.code.to_i)

    if response.is_a?(Net::HTTPSuccess)
      delivery.update!(status: "succeeded", delivered_at: Time.current, last_error: nil)
    else
      delivery.update!(last_error: "HTTP #{response.code}")
      raise DeliveryFailed, "HTTP #{response.code}"
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError, IOError => e
    delivery&.update!(last_error: e.class.name)
    raise DeliveryFailed, e.class.name
  end

  private

  # Connects to the address WebhookEndpoint.public_target checked, while the
  # Host header, TLS SNI and certificate check use the hostname. Redirects
  # are not followed: a 3xx is a failed attempt.
  def post(target, endpoint, delivery, body)
    uri = target.uri
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["User-Agent"] = "Kinko-Webhooks/1.0"
    request["Kinko-Event-Id"] = delivery.payload["id"]
    request["Kinko-Signature"] = Webhooks::Signature.header(body, endpoint.signing_secret)
    request.body = body

    options = { use_ssl: uri.scheme == "https", open_timeout: TIMEOUT, read_timeout: TIMEOUT }
    options[:ipaddr] = target.ip if target.ip
    Net::HTTP.start(uri.host, uri.port, **options) do |http|
      http.request(request)
    end
  end
end
