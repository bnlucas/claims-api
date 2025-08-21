# frozen_string_literal: true

# Wraps access to the current request's authorization context.
#
# This is primarily backed by `RequestStore.store[:auth]`, which contains:
# - :token    => raw JWT token string
# - :customer => Customer instance
# - :scopes  => array of derived scope strings
#
# All other values (IDs, role, etc.) are derived on demand.
#
class AuthInfo
  # Returns the singleton `AuthInfo` instance for the current request.
  # It initializes a new instance with the data from `RequestStore`.
  #
  # @return [AuthInfo] The singleton instance.
  def self.current
    new(RequestStore.store[:auth] || {})
  end

  # Initializes the `AuthInfo` instance with data from the request store.
  #
  # @param store [Hash] A hash containing authentication data.
  def initialize(store)
    @store = store
  end

  # Returns the raw JWT token string.
  #
  # @return [String, nil] The raw token string or `nil` if not present.
  def token
    @store[:token]
  end

  # Returns the authenticated `Customer` instance.
  #
  # @return [Customer] The customer object.
  # @raise [UnauthorizedError] If no customer is associated with the request.
  def customer
    @store[:customer] || raise(UnauthorizedError, "Missing customer")
  end

  # Returns the ID of the authenticated customer.
  # This method is a convenience wrapper around `#customer`.
  #
  # @return [String] The customer's ID.
  def customer_id
    customer.id
  end

  # Returns an array of scopes granted to the user.
  # Scopes are typically derived from the user's role or the JWT token.
  #
  # @return [Array<String>] A list of scopes.
  def scopes
    Array(@store[:scopes]).compact
  end

  # Checks if the user has a specific scope.
  #
  # @param scope [String] The scope to check for.
  # @return [Boolean] `true` if the user has the scope, `false` otherwise.
  def has_scope?(scope)
    scopes.include?(scope)
  end

  # Returns an array of scopes from a required list that are missing.
  #
  # @param required [Array<String>] A list of scopes to check against.
  # @return [Array<String>] The list of missing scopes.
  def missing_scopes(required)
    required.flatten - scopes
  end

  # Checks if the user has all of the required scopes.
  #
  # @param required [Array<String>] A list of scopes that are all required.
  # @return [Boolean] `true` if the user has all the scopes, `false` otherwise.
  def has_all_scopes?(*required)
    missing_scopes(required).empty?
  end

  # Checks if the user has at least one of the provided scopes.
  #
  # @param options [Array<String>] A list of scopes, of which at least one is required.
  # @return [Boolean] `true` if the user has any of the scopes, `false` otherwise.
  def has_any_scope?(*options)
    options.flatten.any? { |s| has_scope?(s) }
  end
end
