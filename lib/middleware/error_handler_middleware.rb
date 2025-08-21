# frozen_string_literal: true

# `ErrorHandlerMiddleware` is a Rack middleware that provides a centralized
# mechanism for handling exceptions in the application. It catches both custom
# `HttpError` exceptions and standard Ruby exceptions, converting them into
# standardized JSON error responses.
class ErrorHandlerMiddleware
  # Initializes the middleware.
  #
  # @param app [Object] The next application in the Rack middleware stack.
  def initialize(app)
    @app = app
  end

  # The main entry point for the middleware. It calls the next middleware
  # and rescues from various exceptions to provide a consistent error response.
  #
  # @param env [Hash] The Rack environment hash.
  # @return [Array] A Rack response tuple `[status, headers, body]`.
  # @rescue [HttpError] Catches custom HTTP errors and renders a JSON response with the error's status and details.
  # @rescue [StandardError] Catches all other unhandled exceptions, logs them, and renders a generic "Internal Server Error" response.
  def call(env)
    @app.call(env)
  rescue HttpError => e
    render_error(e.status, e.to_h)
  rescue StandardError => e
    Rails.logger.error("[Unhandled Exception] #{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}")
    render_error(500, { message: "Internal Server Error" })
  end

  private

  # Renders a standardized JSON error response.
  #
  # @param status [Integer] The HTTP status code to return.
  # @param body [Hash] The error details to be included in the JSON body.
  # @return [Array] The Rack response array.
  def render_error(status, body)
    body = body.to_json if body.respond_to?(:to_h)

    headers = {
      "Content-Type" => "application/json",
      "Content-Length" => body.bytesize.to_s
    }

    apply_rate_limit_headers!(headers)
    [ status, headers, [ body ] ]
  end

  # Adds rate-limiting headers to the response if they are present in the `RequestStore`.
  #
  # @param headers [Hash] The response headers hash.
  # @return [Hash] The headers hash with rate-limiting headers added.
  def apply_rate_limit_headers!(headers)
    rate_limit_headers = {
      "RateLimit-Remaining" => RequestStore.store[:rate_limit_remaining],
      "RateLimit-Reset" => RequestStore.store[:rate_limit_reset_in]
    }.compact.transform_values(&:to_s)

    headers.merge!(rate_limit_headers)
  end
end
