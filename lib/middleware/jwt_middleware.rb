# frozen_string_literal: true

require_relative "generic_auth_middleware"

# A Rack middleware that authenticates requests using a JSON Web Token (JWT).
#
# It decodes the token, validates its claims, fetches the corresponding customer,
# and checks if the token has been blocklisted. If authentication is successful,
# it populates a `RequestStore` with the authentication context for use by the
# application layer.
class JwtMiddleware < GenericAuthMiddleware
  # Processes the incoming Rack request to authenticate with a JWT.
  #
  # @param env [Hash] The Rack environment hash.
  # @return [Array] The Rack response, either by calling the next middleware in the stack
  #   or by returning an unauthorized response.
  def call(env)
    # Skip if already authorized by a preceding middleware (e.g., API key).
    return @app.call(env) if RequestStore.store[:auth]&.dig(:customer)

    token = extract_token(env)
    payload = TokenDecoder.decode!(token)

    validate_claims!(payload)

    customer = fetch_customer!(payload["sub"])
    raise UnauthorizedError, "Token has been revoked" if TokenBlocklist.revoked?(payload["jti"])

    populate_request_store(token, customer, payload)
    @app.call(env)
  rescue TokenDecoder::DecodeError => e
    unauthorized_response("Invalid token: #{e.message}")
  rescue UnauthorizedError => e
    unauthorized_response(e.message)
  rescue JWT::DecodeError => e
    unauthorized_response(e.message)
  end

  private

  # Extracts the JWT from the `Authorization` header by stripping the "Bearer " prefix.
  #
  # @param env [Hash] The Rack environment hash.
  # @return [String] The raw JWT string.
  def extract_token(env)
    auth = env["HTTP_AUTHORIZATION"].to_s
    auth.sub(/^Bearer\s/, "")
  end

  # Validates that the JWT payload contains all required claims.
  #
  # @param payload [Hash] The decoded JWT payload.
  # @return [void]
  # @raise [UnauthorizedError] If a required claim is missing.
  def validate_claims!(payload)
    %w[aud sub jti scopes].each do |key|
      raise UnauthorizedError, "Missing required claim: #{key}" unless payload[key].present?
    end
  end

  # Fetches the `Customer` record based on the `sub` (subject) claim in the JWT.
  # It also performs checks to ensure the customer is active and not soft-deleted.
  #
  # @param id [String] The customer ID from the JWT payload.
  # @return [Customer] The authenticated customer object.
  # @raise [UnauthorizedError] If the customer is not found or is inactive/deleted.
  def fetch_customer!(id)
    customer = Customer.find_by!(id: id)
    # Check if the customer is both active and not soft-deleted.
    raise UnauthorizedError, "Customer inactive or deleted" unless customer.active? && !customer.deleted?

    # There's a small bug here. This should return `customer`, not `user`.
    customer
  rescue ActiveRecord::RecordNotFound
    raise UnauthorizedError, "Customer not found"
  end

  # Populates the `RequestStore` with authentication details.
  # This makes the authentication context available to the rest of the application.
  #
  # @param token [String] The raw JWT token.
  # @param customer [Customer] The authenticated customer record.
  # @param payload [Hash] The decoded JWT payload.
  # @return [void]
  def populate_request_store(token, customer, payload)
    RequestStore.store[:auth] = {
      token: token,
      customer: customer,
      jti: payload["jti"],
      scopes: payload["scopes"]
    }
  end
end
