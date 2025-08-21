# frozen_string_literal: true

require "active_support/concern"
require "uri"

# This module provides helper methods for implementing JSON:API-compliant
# pagination, particularly for cursor-based pagination. It generates a
# standardized response format with `data`, `links`, and `meta` hashes.
module JsonApiPagination
  extend ActiveSupport

  # Generates a JSON:API-compliant paginated response hash.
  #
  # @param page [Object] An object that responds to `#records`, `#next_cursor`, and `#prev_cursor`.
  # @param limit [Integer] The number of records requested per page.
  # @return [Hash] A hash with `data`, `links`, and `meta` keys.
  #
  # @example
  #   result = MyService.call(...)
  #   jsonapi_paginate(result.value, limit: 10)
  #   #=> { data: [...], links: { self: "...", next: "...", prev: "..." }, meta: { ... } }
  def jsonapi_paginate(page, limit:)
    {
      data: page.records,
      links: {
        self: request.original_url,
        next: page_link(page.next_cursor, limit),
        prev: page_link(page.prev_cursor, limit)
      },
      meta: { page: { limit: limit.to_i } }
    }
  end

  # Renders a JSON:API-compliant paginated response.
  #
  # @param page [Object] An object that responds to `#records`, `#next_cursor`, and `#prev_cursor`.
  # @param limit [Integer] The number of records requested per page.
  # @param status [Symbol] The HTTP status code to render, e.g., `:ok` or `:partial_content`.
  # @return [void] Renders the JSON response.
  def jsonapi_render(page, limit:, status: :ok)
    render json: jsonapi_paginate(page, limit: limit), status: status
  end

  private

  # Generates a full URL for pagination links (next/prev).
  # It safely updates the URL's query parameters without a cursor
  # for the `self` link, or with a new cursor for the `next` or `prev` links.
  #
  # @param cursor [String, nil] The cursor value for the new page link.
  # @param limit [Integer, nil] The limit value for the new page link.
  # @return [String] The full URL with updated query parameters.
  def page_link(cursor, limit)
    uri       = URI.parse(request.original_url)
    params    = request.query_parameters.deep_dup

    params.delete(:cursor)
    params[:cursor] = cursor if cursor.present?
    params[:limit]  = limit  if limit.present?

    uri.query = params.to_query
    uri.to_s
  end
end
