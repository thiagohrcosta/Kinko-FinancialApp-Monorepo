# A Kinko API key issued to a merchant (business user). Kinko keys are the
# only credential merchants get: they never see or use Stripe keys.
#
# Format: "kinko_sk_" + 40 base62 chars. Only the SHA-256 digest is stored,
# so a database leak does not expose usable keys; the plain key is returned
# once, at creation.
class MerchantApiKey < ApplicationRecord
  PREFIX = "kinko_sk_".freeze

  belongs_to :user

  validates :name, presence: true, length: { maximum: 60 }
  validate :user_must_be_business, on: :create

  scope :active, -> { where(revoked_at: nil) }

  attr_reader :plain_token

  def self.issue!(user:, name:)
    token = "#{PREFIX}#{SecureRandom.alphanumeric(40)}"
    key = create!(user: user, name: name, token_digest: digest(token), last4: token[-4..])
    key.instance_variable_set(:@plain_token, token)
    key
  end

  def self.authenticate(token)
    return nil unless token.to_s.start_with?(PREFIX)

    active.includes(:user).find_by(token_digest: digest(token))
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked?
  end

  def revoked?
    revoked_at.present?
  end

  # Avoids a write on every request: last_used_at is a hint, not an audit log.
  def touch_last_used!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 1.minute.ago
  end

  def masked
    "#{PREFIX}…#{last4}"
  end

  def as_json(*)
    {
      id: id,
      name: name,
      masked_key: masked,
      created_at: created_at&.iso8601,
      last_used_at: last_used_at&.iso8601,
      revoked_at: revoked_at&.iso8601
    }
  end

  private

  def user_must_be_business
    errors.add(:user, "must be a business account") unless user&.business?
  end
end
