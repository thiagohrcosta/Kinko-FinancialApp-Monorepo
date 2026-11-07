require "openssl"
require "securerandom"

module Payments
  # The copy-and-paste payment code, e.g. "KNK1" + 20 random chars + 4 check chars:
  #
  #   KNK1 7G2MXQ9TBV4KC8RZD1WN P3HE
  #   ^    ^                    ^
  #   |    100 random bits      HMAC checksum (rejects typos / made-up codes
  #   |                         before any database lookup)
  #   version prefix
  #
  # The code carries no payment data: it only points to a PaymentRequest on
  # the server, so editing the text can never change the amount or the payee.
  # Crockford base32 has no I, L, O or U, and parsing maps the look-alikes
  # (o→0, i/l→1), so codes survive being read aloud or retyped.
  module PaymentCode
    PREFIX = "KNK1".freeze
    ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".freeze
    BODY_LENGTH = 20
    CHECK_LENGTH = 4
    LENGTH = PREFIX.length + BODY_LENGTH + CHECK_LENGTH

    class InvalidCode < StandardError
      def initialize(msg = "Invalid payment code")
        super
      end
    end

    module_function

    def generate
      body = Array.new(BODY_LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
      "#{PREFIX}#{body}#{checksum(body)}"
    end

    # Returns the canonical code, or raises InvalidCode.
    def normalize!(input)
      code = input.to_s.upcase.gsub(/[\s-]/, "").tr("OIL", "011")
      raise InvalidCode unless code.length == LENGTH && code.start_with?(PREFIX)

      body = code[PREFIX.length, BODY_LENGTH]
      check = code[-CHECK_LENGTH..]
      raise InvalidCode unless body.each_char.all? { |c| ALPHABET.include?(c) }
      raise InvalidCode unless OpenSSL.fixed_length_secure_compare(checksum(body), check)

      code
    end

    def valid?(input)
      normalize!(input)
      true
    rescue InvalidCode
      false
    end

    def checksum(body)
      digest = OpenSSL::HMAC.digest("SHA256", secret, "#{PREFIX}#{body}")
      digest.bytes.first(CHECK_LENGTH).map { |b| ALPHABET[b % ALPHABET.length] }.join
    end

    def secret
      @secret ||= Rails.application.key_generator.generate_key("kinko/payment_code", 32)
    end
  end
end
