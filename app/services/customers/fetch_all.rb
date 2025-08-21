# frozen_string_literal: true

module Customers
  # `Customers::FetchAll` is a service object that fetches a paginated list of customers.
  # It supports filtering, fuzzy searching, and including soft-deleted records using
  # cursor-based pagination.
  class FetchAll < ApplicationService
    use_contract :service

    # The maximum number of records that can be returned in a single request.
    MAX_LIMIT = 1_000

    # Fetches a list of customers based on provided filters and pagination parameters.
    #
    # @param query [String, nil] An optional search query for fuzzy matching against
    #   customer attributes like first name, last name, and email.
    # @param limit [Integer] The number of customers to return per page. Defaults to `100`.
    # @param cursor [String, nil] The pagination cursor to fetch the next set of results.
    # @param include_deleted [Boolean] Flag to include soft-deleted customers in the results.
    #   Defaults to `false`.
    # @return [Gaskit::ServiceResult] A successful result containing a `Page` object,
    #   which includes the fetched records and pagination cursors.
    def call(query: nil, limit: 100, cursor: nil, include_deleted: false)
      limit = limit.to_i.clamp(1, MAX_LIMIT)

      rel = ::Customer.all
      rel = rel.active unless include_deleted
      rel = rel.fuzzy_find(%i[first_name last_name email], query) if query.present?
      rel = rel.order_for_relay.apply_cursor(after: cursor).limit(limit)

      records = rel.to_a

      page = Page.new(
        records: records,
        next_cursor: records.last&.cursor,
        prev_cursor: records.first&.cursor
      )

      page
    end
  end
end
