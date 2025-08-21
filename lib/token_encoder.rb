# frozen_string_literal: true

require "jwt"
require "openssl"

# `TokenEncoder` is responsible for generating signed JSON Web Tokens (JWTs).
# It uses the RS256 algorithm with a private key to ensure token integrity.
# The class automatically adds standard claims such as issuer, expiration time,
# issued-at time, and a unique JWT ID.
class TokenEncoder
  # The cryptographic algorithm used for signing the JWT.
  ALGORITHM = "RS256"
  # The default expiration time for generated tokens.
  EXPIRATION = 15.minutes

  # Encodes and signs a given payload into a JWT.
  #
  # @param payload [Hash] The data to be included in the token.
  # @return [String] The signed JWT as a string.
  #
  # @example
  #   token = TokenEncoder.encode!(user_id: 123, scopes: ["read:profile"])
  #   #=> "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.ey..."
  def self.encode!(payload)
    payload = payload.dup.merge(
      iss: "claims-api",
      exp: EXPIRATION.from_now.to_i,
      iat: Time.now.to_i,
      jti: SecureRandom.uuid
    )

    JWT.encode(payload, private_key, ALGORITHM)
  end

  # Retrieves the private key used for signing JWTs.
  # The key is read from a file and memoized for performance.
  #
  # @return [OpenSSL::PKey::RSA] The private key object.
  def self.private_key
    @private_key ||= OpenSSL::PKey::RSA.new(File.read(Rails.root.join("config/keys/private_key.pem")))
  end
end
