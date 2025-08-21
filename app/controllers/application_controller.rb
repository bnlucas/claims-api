# frozen_string_literal: true

# The base class for all controllers in the application.
# It includes modules for authentication and JSON:API pagination,
# and defines common methods and class-level macros for authorization.
class ApplicationController < ActionController::API
  include AuthContext
  include JsonApiPagination

  # @!visibility private
  PAGINATION_LIMIT = 500
  # @!visibility private
  MAX_PAGINATION_LIMIT = 1_000

  class << self
    # A class macro to apply scope-based authorization to one or more controller actions.
    # It sets up a `before_action` that checks if the user has the required scopes.
    #
    # @param actions [Symbol, Array<Symbol>] The name(s) of the action(s) to protect.
    # @param scopes [Array<String>] The scopes required to access the action(s).
    # @param any_of [Boolean] If `true`, the user must have at least one of the scopes.
    # @return [void]
    #
    # @example
    #   require_scopes :show, "read:claim", "read:customer"
    #
    # @example
    #   require_scopes [:index, :show], "read:claim"
    def require_scopes(actions, *scopes, any_of: false)
      Array(actions).each do |action|
        before_action -> { require_scopes!(*scopes, any_of: any_of) }, only: action
      end
    end

    # A convenience class macro for protecting a single action with a single scope.
    #
    # @param action [Symbol] The name of the action to protect.
    # @param scope [String] The scope required to access the action.
    # @return [void]
    #
    # @example
    #   require_scope :show, "read:claim"
    def require_scope(action, scope)
      require_scopes(action, scope)
    end
  end

  # Raises a `NotFoundError` for a route that does not match any defined routes.
  # This method is typically used in the routes file to provide a catch-all for unknown endpoints.
  #
  # @raise [NotFoundError] with the message "Not Found".
  def route_not_found
    raise NotFoundError, "Not Found"
  end

  # A helper method to retrieve the `Customer` record associated with the current authenticated user.
  #
  # @return [Customer] The customer object.
  # @raise [NoMethodError] if `AuthInfo.current` is not available or does not have a `customer`.
  def current_customer
    AuthInfo.current.customer
  end
end
