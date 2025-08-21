# frozen_string_literal: true

module Claims
  # `Claims::FetchAll` is a service object that fetches a paginated list of claims
  # for a given customer. It supports filtering, searching, and including soft-deleted
  # records using cursor-based pagination.
  class FetchAll < ApplicationService
    # The maximum number of records that can be returned in a single request.
    MAX_LIMIT = 1_000

    # Fetches a list of claims based on provided filters and pagination parameters.
    #
    # @param customer_id [String] The ID of the customer whose claims are being fetched.
    # @param query [String, nil] An optional search query for fuzzy matching against claim attributes.
    # @param limit [Integer] The number of claims to return per page. Defaults to `100`.
    # @param cursor [String, nil] The pagination cursor to fetch the next set of results.
    # @param include_deleted [Boolean] Flag to include soft-deleted claims in the results.
    #   Defaults to `false`.
    # @return [Gaskit::ServiceResult] A successful result containing a `Page` object,
    #   which includes the fetched records and pagination cursors.
    def call(customer_id:, query: nil, limit: 100, cursor: nil, include_deleted: false)
      limit = limit.to_i.clamp(1, MAX_LIMIT)

      rel = ::Claim.where(customer_id: customer_id)
      rel = rel.active unless include_deleted
      rel = rel.fuzzy_find(:description, query) if query.present?
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
