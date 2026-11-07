require "ipaddr"
require "resolv"

# The URL where Kinko notifies a merchant about its payment requests.
# One endpoint per merchant.
class WebhookEndpoint < ApplicationRecord
  SECRET_PREFIX = "kinko_whsec_".freeze

  belongs_to :user
  has_many :deliveries, class_name: "WebhookDelivery", dependent: :destroy

  validates :url, presence: true, length: { maximum: 500 }
  validate :url_must_be_safe

  before_validation :assign_secret, on: :create

  def rotate_secret!
    update!(signing_secret: self.class.generate_secret)
  end

  def self.generate_secret
    "#{SECRET_PREFIX}#{SecureRandom.alphanumeric(40)}"
  end

  # Blocks requests to the server's own network (SSRF). Checked on save and
  # again right before each delivery, because DNS can change in between.
  def self.safe_url?(raw)
    uri = URI.parse(raw.to_s)
    return false unless uri.is_a?(URI::HTTP) && uri.host.present?
    return false if uri.scheme != "https" && !allow_insecure?
    return true if allow_insecure? # dev/test: local receivers are expected

    addresses = Resolv.getaddresses(uri.host)
    addresses.any? && addresses.none? { |ip| private_address?(ip) }
  rescue URI::InvalidURIError
    false
  end

  def self.private_address?(ip)
    addr = IPAddr.new(ip)
    addr.loopback? || addr.private? || addr.link_local? ||
      IPAddr.new("0.0.0.0/8").include?(addr) || IPAddr.new("100.64.0.0/10").include?(addr)
  rescue IPAddr::InvalidAddressError
    true
  end

  def self.allow_insecure?
    Rails.env.local?
  end

  def as_json(*)
    { url: url, active: active, signing_secret: signing_secret, updated_at: updated_at&.iso8601 }
  end

  private

  def assign_secret
    self.signing_secret ||= self.class.generate_secret
  end

  def url_must_be_safe
    return if url.blank?

    errors.add(:url, "must be a public https URL") unless self.class.safe_url?(url)
  end
end
