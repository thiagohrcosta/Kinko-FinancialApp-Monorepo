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

  # Where a delivery goes: the parsed URL and the IP address to connect to.
  Target = Data.define(:uri, :ip)

  # Special-use ranges that are not "private" in IPAddr's sense but must not
  # be reachable either: this network, CGNAT, IETF/test nets, benchmarking,
  # multicast, reserved, broadcast; IPv6 unspecified, NAT64, documentation,
  # multicast.
  BLOCKED_RANGES = %w[
    0.0.0.0/8 100.64.0.0/10 192.0.0.0/24 192.0.2.0/24 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24
    224.0.0.0/4 240.0.0.0/4 255.255.255.255/32
    ::/128 64:ff9b::/96 2001:db8::/32 ff00::/8
  ].map { |range| IPAddr.new(range) }.freeze

  # Blocks requests to the server's own network (SSRF). The host is resolved
  # once, every address must be public, and the delivery connects to the
  # address checked here, so DNS can't point somewhere else between the check
  # and the request (DNS rebinding). Checked on save and before each delivery.
  def self.public_target(raw)
    uri = URI.parse(raw.to_s)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?
    return if uri.scheme != "https" && !allow_insecure?
    return Target.new(uri: uri, ip: nil) if allow_insecure? # dev/test: local receivers are expected

    addresses = Resolv.getaddresses(uri.host)
    return if addresses.empty? || addresses.any? { |ip| private_address?(ip) }

    Target.new(uri: uri, ip: addresses.first)
  rescue URI::InvalidURIError
    nil
  end

  def self.safe_url?(raw)
    public_target(raw).present?
  end

  def self.private_address?(ip)
    addr = IPAddr.new(ip).native # ::ffff:10.0.0.1 is 10.0.0.1
    addr.loopback? || addr.private? || addr.link_local? || BLOCKED_RANGES.any? { |range| range.include?(addr) }
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
