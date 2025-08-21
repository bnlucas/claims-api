# frozen_string_literal: true

require "jwt"
require "openssl"

# `TokenDecoder` is responsible for decoding and validating JSON Web Tokens (JWTs)
# received from a client. It uses the RS256 algorithm with a public key to verify
# the token's signature and ensures that all required claims are present.
class TokenDecoder
  # The cryptographic algorithm used for decoding and verifying the JWT.
  ALGORITHM = "RS256"

  # Base class for all token-related decoding errors.
  class DecodeError < StandardError; end
  # Raised when the token's expiration time has passed.
  class ExpiredTokenError < DecodeError; end
  # Raised when the token is malformed, missing, or has an invalid signature.
  class InvalidTokenError < DecodeError; end

  # Decodes and validates a JWT string.
  #
  # This method performs several checks:
  # 1. Ensures the token is not blank.
  # 2. Verifies the token's signature using the public key.
  # 3. Checks for token expiration.
  # 4. Validates that all required claims (`aud`, `sub`, `jti`) are present.
  #
  # @param token [String] The raw JWT from the `Authorization` header.
  # @return [Hash] The decoded payload as a hash.
  # @raise [InvalidTokenError] if the token is missing, malformed, or has an invalid signature.
  # @raise [ExpiredTokenError] if the token has expired.
  def self.decode!(token)
    raise InvalidTokenError, "Missing token" if token.blank?

    payload, _ = JWT.decode(
      token,
      public_key,
      true, # verify signature
      algorithm: ALGORITHM
    )

    validate_payload!(payload)
    payload
  rescue JWT::ExpiredSignature
    raise ExpiredTokenError, "Token has expired"
  rescue JWT::DecodeError => e
    raise InvalidTokenError, "Token decoding failed: #{e.message}"
  end

  # Loads the RSA public key from a file and memoizes it.
  #
  # @return [OpenSSL::PKey::RSA] The public key object used for signature verification.
  def self.public_key
    @public_key ||= OpenSSL::PKey::RSA.new(File.read(Rails.root.join("config/keys/public_key.pem")))
  end

  # Ensures required claims are present in the JWT payload.
  #
  # @param payload [Hash] The decoded JWT payload.
  # @raise [InvalidTokenError] if any of the required claims (`aud`, `sub`, `jti`) are missing.
  def self.validate_payload!(payload)
    raise InvalidTokenError, "aud missing" unless payload["aud"]
    raise InvalidTokenError, "sub missing" unless payload["sub"]
    raise InvalidTokenError, "jti missing" unless payload["jti"]
  end
end
