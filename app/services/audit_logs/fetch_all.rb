# frozen_string_literal: true

module AuditLogs
  # `AuditLogs::FetchAll` is a service object that retrieves a paginated
  # list of audit logs. It filters logs by customer ID and optionally by
  # claim ID, using cursor-based pagination for efficient retrieval.
  class FetchAll < ApplicationService
    use_contract :service

    # The maximum number of records that can be returned in a single request.
    MAX_LIMIT = 1_000

    # Fetches a paginated list of audit logs for a given customer, optionally
    # filtered by a specific claim ID.
    #
    # @param customer_id [String] The ID of the customer whose audit logs are being fetched.
    # @param claim_id [String, nil] The ID of a specific claim to filter the audit logs by.
    #   Defaults to `nil`.
    # @param limit [Integer] The number of records to return per page. Defaults to `100`.
    #   The value is clamped between `1` and `MAX_LIMIT`.
    # @param cursor [String, nil] The pagination cursor to fetch the next page of results.
    # @return [Gaskit::ServiceResult] A successful result containing a `Page` object,
    #   which includes the fetched records and pagination cursors.
    def call(customer_id:, claim_id: nil, limit: 100, cursor: nil)
      limit = limit.to_i.clamp(1, MAX_LIMIT)

      rel = ::AuditLog.where(customer_id: customer_id)
      rel = rel.where(claim_id: claim_id) if claim_id
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
