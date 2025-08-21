# frozen_string_literal: true

# An error raised when the client's request is invalid or malformed.
# It corresponds to a `400 Bad Request` HTTP status.
class BadRequestError < HttpError
  status 400
end

# An error raised when the client is not authenticated.
# It corresponds to a `401 Unauthorized` HTTP status.
class UnauthorizedError < HttpError
  status 401
end

# An error raised when the client is authenticated but does not have
# permission to access the requested resource.
# It corresponds to a `403 Forbidden` HTTP status.
class ForbiddenError < HttpError
  status 403
end

# An error raised when the requested resource could not be found.
# It corresponds to a `404 Not Found` HTTP status.
class NotFoundError < HttpError
  status 404
end

# An error raised when a request conflicts with the current state of the resource.
# For example, attempting to create a record that already exists.
# It corresponds to a `409 Conflict` HTTP status.
class ConflictError < HttpError
  status 409
end

# An error raised when the server understands the request but cannot process it
# due to semantic errors (e.g., validation failures).
# It corresponds to a `422 Unprocessable Entity` HTTP status.
class UnprocessableEntityError < HttpError
  status 422
end

# An error raised when the client has sent too many requests in a given amount of time.
# It corresponds to a `429 Too Many Requests` HTTP status.
class RateLimitExceededError < HttpError
  status 429
end

# A generic error for internal server issues that are not the client's fault.
# It corresponds to a `500 Internal Server Error` HTTP status.
class InternalServerError < HttpError
  status 500
end

# An error raised when the server is not ready to handle the request.
# This is often a temporary condition, such as during maintenance.
# It corresponds to a `503 Service Unavailable` HTTP status.
class ServiceUnavailableError < HttpError
  status 503
end
