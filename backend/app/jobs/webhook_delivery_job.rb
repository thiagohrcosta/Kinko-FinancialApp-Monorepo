require "net/http"

# Sends one webhook to a merchant and retries with backoff until it gets a
# 2xx. Merchants verify the Kinko-Signature header (see Webhooks::Signature).
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  MAX_ATTEMPTS = 8
  TIMEOUT = 5 # seconds

  class DeliveryFailed < StandardError; end

  retry_on DeliveryFailed, wait: :polynomially_longer, attempts: MAX_ATTEMPTS do |job, _error|
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
    unless WebhookEndpoint.safe_url?(endpoint.url)
      delivery.update!(last_error: "Unsafe URL")
      raise DeliveryFailed, "Unsafe URL"
    end

    response = post(endpoint, delivery, body)
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

  def post(endpoint, delivery, body)
    uri = URI.parse(endpoint.url)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["User-Agent"] = "Kinko-Webhooks/1.0"
    request["Kinko-Event-Id"] = delivery.payload["id"]
    request["Kinko-Signature"] = Webhooks::Signature.header(body, endpoint.signing_secret)
    request.body = body

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                        open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.request(request)
    end
  end
end
