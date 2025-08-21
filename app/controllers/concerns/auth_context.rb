# frozen_string_literal: true

# AuthContext provides methods for scope-based authorization within a request.
# It checks if the current user (from `AuthInfo.current`) has the necessary scopes
# to perform an action.
module AuthContext
  # Requires the current user to have all specified scopes.
  # If the user has the "admin" scope, the check is bypassed.
  #
  # @param scopes [Array<String>] A list of scopes that the user must have.
  # @param any_of [Boolean] If true, the user must have at least one of the specified scopes.
  # @return [void]
  # @raise [UnauthorizedError] if the user is missing any of the required scopes.
  #   The error includes details about which scopes were required and which were available.
  def require_scopes!(*scopes, any_of: false)
    auth = AuthInfo.current

    return if auth.has_scope?("admin")
    return require_any_scope!(*scopes, auth:) if any_of

    missing = scopes.flatten - auth.scopes
    return if missing.empty?

    raise UnauthorizedError.new(
      "Missing required scope(s): #{missing.join(', ')}",
      code: "missing_scope",
      context: { required: scopes, available: auth.scopes }
    )
  end

  # Requires the current user to have at least one of the specified scopes.
  #
  # @param scopes [Array<String>] A list of scopes. The user must possess at least one of them.
  # @param auth [AuthInfo] The authentication information object, defaults to `AuthInfo.current`.
  # @return [void]
  # @raise [UnauthorizedError] if the user does not have any of the required scopes.
  #   The error includes details about the required and available scopes.
  def require_any_scope!(*scopes, auth: AuthInfo.current)
    return if scopes.any? { |scope| auth.has_scope?(scope) }

    raise UnauthorizedError.new(
      "Requires one of: #{scopes.join(', ')}",
      code: "missing_scope",
      context: { required: scopes, available: auth.scopes }
    )
  end
end
