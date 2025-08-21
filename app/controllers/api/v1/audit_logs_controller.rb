# frozen_string_literal: true

module Api
  module V1
    # AuditLogsController manages API endpoints for retrieving audit logs.
    # It delegates business logic to `AuditLogs` service objects and ensures
    # requests are authorized with the correct scopes.
    class AuditLogsController < ApplicationController
      # Requires the 'read:audit_logs' scope for all methods.
      require_scope :index, "read:audit_logs"
      require_scope :claim,  "read:audit_logs"

      # Retrieves a paginated list of all audit logs for the authenticated customer.
      #
      # @param params [Hash] The request parameters.
      # @option params [Integer] :limit The number of records to return per page.
      # @option params [String] :cursor The pagination cursor for fetching the next page.
      # @option params [Boolean] :include_deleted A flag to include soft-deleted records.
      # @return [JSON] A paginated list of audit logs.
      # @example GET /audit_logs?limit=50&cursor=somecursor
      def index
        limit = (params[:limit].presence&.to_i || PAGINATION_LIMIT).clamp(1, MAX_PAGINATION_LIMIT)

        result = ::AuditLogs::FetchAll.call(
          customer_id: current_customer.id,
          limit: limit,
          cursor: params[:cursor].presence
        )

        response = jsonapi_paginate(result.value, limit: limit)
        render json: response, status: 200
      end

      # Retrieves a paginated list of audit logs for a specific claim.
      #
      # @param params [Hash] The request parameters.
      # @option params [String] :id The ID of the claim whose logs are being fetched.
      # @option params [Integer] :limit The number of records to return.
      # @option params [String] :cursor The pagination cursor for fetching the next page.
      # @return [JSON] A paginated list of audit logs for the claim.
      # @example GET /audit_logs/claims/123e4567-e89b-12d3-a456-426614174000
      def claim
        limit = (params[:limit].presence&.to_i || PAGINATION_LIMIT).clamp(1, MAX_PAGINATION_LIMIT)

        result = ::AuditLogs::FetchAll.call(
          customer_id: current_customer.id,
          claim_id: params[:id],
          limit: limit,
          cursor: params[:cursor].presence
        )

        response = jsonapi_paginate(result.value, limit: limit)
        render json: response, status: 200
      end

      # Note: The `customers` action is declared with `require_scope`, but no method
      # is defined. A method here would typically handle audit logs for a specific customer.

      private

      # Retrieves the claim ID from the request parameters.
      # @return [String] The claim ID.
      def id
        params[:id]
      end
    end
  end
end
