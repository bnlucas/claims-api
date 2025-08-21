# frozen_string_literal: true

# The `HttpError` class is a custom exception for handling HTTP-level errors.
# It is designed to be caught by a middleware, allowing for standardized
# error responses with a specific HTTP status, a custom message, an optional
# error code, and a context hash for extra details.
class HttpError < ApplicationError
  class << self
    # @!attribute [r] http_status
    # @return [Integer] The HTTP status code associated with the error class.
    attr_reader :http_status

    # Sets the HTTP status code for the error class.
    # @param code [Integer] The HTTP status code (e.g., 404, 401).
    def status(code)
      @http_status = code
    end
  end

  # @return [String, nil] The structured error code.
  attr_reader :code
  # @return [Hash] A hash of key-value pairs providing additional context about the error.
  attr_reader :context

  # Initializes a new `HttpError` instance.
  # @param message [String, nil] A human-readable message for the error.
  # @param code [String, nil] A structured error code.
  # @param context [Hash] A hash of key-value pairs for additional context.
  # @param backtrace [Array<String>, nil] The backtrace for the exception. Defaults to `caller`.
  def initialize(message = nil, code: nil, context: {}, backtrace: nil)
    backtrace ||= caller

    super(message)
    set_backtrace(backtrace)

    @code = code
    @context = context
  end

  # Converts the error instance into a hash for a JSON response.
  # The hash includes the message, code, and context.
  # @return [Hash] The hash representation of the error.
  def to_h
    {
      message: message,
      code: code,
      **context
    }
  end

  # Retrieves the HTTP status code for the error instance.
  # It defaults to 500 if no status is defined for the class.
  # @return [Integer] The HTTP status code.
  def status
    self.class.http_status || 500
  end
end
