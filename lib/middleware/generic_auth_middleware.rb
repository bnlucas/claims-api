# frozen_string_literal: true

# The base class for all authentication middleware in the application.
# It provides a common interface for processing Rack requests and handles
# the standardized `401 Unauthorized` response when an authentication
# error occurs. Subclasses should inherit from this class and implement
# their specific authentication logic.
class GenericAuthMiddleware
  # Initializes the middleware.
  #
  # @param app [Object] The next application in the Rack middleware stack.
  def initialize(app)
    @app = app
  end

  # The main entry point for the middleware. This method is a template
  # that must be implemented by subclasses.
  #
  # @param env [Hash] The Rack environment hash.
  # @return [Array] The Rack response, typically a 3-element array of `[status, headers, body]`.
  # @raise [NotImplementedError] This base method raises an error to ensure subclasses implement their own authentication logic.
  # @rescue [UnauthorizedError] Catches `UnauthorizedError` and returns a standardized `401 Unauthorized` response.
  def call(env)
    raise NotImplementedError, "Subclasses must implement `authenticate!`"

    @app.call(env)
  rescue UnauthorizedError => e
    unauthorized_response(e.message)
  end

  private

  # Generates a standard `401 Unauthorized` Rack response.
  #
  # @param message [String] The error message to be included in the JSON response body.
  # @return [Array] A 3-element Rack response array with a 401 status, content type header, and a JSON body.
  def unauthorized_response(message)
    [ 401, { "Content-Type" => "application/json" }, [ { error: message }.to_json ] ]
  end
end
