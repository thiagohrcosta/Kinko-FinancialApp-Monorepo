require "openssl"

module Webhooks
  # Kinko-Signature: t=<unix timestamp>,v1=<hex HMAC-SHA256 of "<t>.<raw body>">
  #
  # Merchants recompute the HMAC with their signing secret over the raw body
  # and reject old timestamps (replay protection), the same scheme as Stripe.
  module Signature
    TOLERANCE = 5 * 60 # seconds

    module_function

    def header(body, secret, timestamp: Time.now.to_i)
      "t=#{timestamp},v1=#{compute(body, secret, timestamp)}"
    end

    def compute(body, secret, timestamp)
      OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
    end

    # Reference implementation of the merchant-side check (used in specs and
    # shown in the docs).
    def valid?(body, header, secret, now: Time.now.to_i)
      parts = header.to_s.split(",").to_h { |kv| kv.split("=", 2) }
      timestamp = Integer(parts["t"], exception: false)
      return false unless timestamp && parts["v1"]
      return false if (now - timestamp).abs > TOLERANCE

      OpenSSL.secure_compare(compute(body, secret, timestamp), parts["v1"])
    end
  end
end
