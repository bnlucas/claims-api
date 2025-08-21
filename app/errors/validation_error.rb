# frozen_string_literal: true

# `ValidationError` is a custom exception for handling `ActiveRecord::RecordInvalid`
# exceptions. It standardizes the error response to be consumed by an API client,
# providing a generic message with a structured `context` containing field-specific errors.
class ValidationError < UnprocessableEntityError
  # Initializes a `ValidationError` from an `ActiveRecord::RecordInvalid` exception.
  #
  # @param record_invalid [ActiveRecord::RecordInvalid] The exception raised by a model validation failure.
  def initialize(record_invalid)
    error_details = format_errors(record_invalid)

    super(
      "One or more parameters are invalid.",
      code: "validation_failed",
      context: { errors: error_details }
    )
  end

  private

  # Formats the errors from an `ActiveRecord::RecordInvalid` exception into a structured array.
  #
  # @param exception [ActiveRecord::RecordInvalid] The validation exception.
  # @return [Array<Hash>] An array of hashes, where each hash contains the `field` and a normalized `code`.
  def format_errors(exception)
    exception.record.errors.map do |error|
      code = normalize_error_code(error.attribute, error.type)

      { field: error.attribute.to_s, code: code }
    end
  end

  # Normalizes an ActiveRecord error attribute and type into a standardized code.
  # This provides a consistent way to handle common validation errors.
  #
  # @param attribute [Symbol] The attribute with the validation error.
  # @param error_type [Symbol] The type of validation error (e.g., `:taken`, `:blank`).
  # @return [String] A normalized string representing the error code.
  def normalize_error_code(attribute, error_type)
    case error_type
    when :taken
      "#{attribute}_taken"
    when :blank
      "#{attribute}_required"
    when :invalid
      "#{attribute}_invalid"
    else
      "#{attribute}_#{error_type}"
    end
  end
end
