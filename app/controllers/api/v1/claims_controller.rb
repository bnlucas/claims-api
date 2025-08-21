# frozen_string_literal: true

module Api
  module V1
    # ClaimsController manages all API endpoints for customer claims.
    # It delegates business logic to `Claims` service objects.
    class ClaimsController < ApplicationController
      require_scope :index,   "read:claim"
      require_scope :show,    "read:claim"
      require_scope :create,  "create:claim"
      require_scope :update,  "update:claim"
      require_scope :destroy, "delete:claim"

      # Fetches a paginated list of claims for the current customer.
      #
      # @route GET /claims
      # @permission read:claim
      #
      # @param limit [Integer] The number of claims to return per page. Defaults to `PAGINATION_LIMIT`.
      # @param cursor [String] The cursor for the next page of results.
      # @param include_deleted [Boolean] Flag to include soft-deleted claims in the results.
      #
      # @response `200 OK` with a JSON body containing a paginated list of claims.
      #   Example:
      #     {
      #       "data": [...],
      #       "links": { "next": "next_cursor_string" }
      #     }
      # @response `500 Internal Server Error` if an unhandled exception occurs in the service.
      def index
        limit = (params[:limit].presence&.to_i || PAGINATION_LIMIT).clamp(1, MAX_PAGINATION_LIMIT)

        result = ::Claims::FetchAll.call(
          customer_id: current_customer.id,
          limit: limit,
          cursor: params[:cursor].presence,
          include_deleted: include_deleted
        )

        # The service now returns an ActiveRecord::Relation. `jsonapi_paginate`
        # will handle the pagination and cursor logic for us.
        response = jsonapi_paginate(result.value, limit: limit)
        render json: response, status: 200
      end

      # Creates a new claim for the current customer.
      #
      # @route POST /claims
      # @permission create:claim
      #
      # @param claim_type [String] The type of the claim.
      # @param description [String] A description of the claim.
      # @param amount_claimed [Decimal] The monetary amount of the claim.
      #
      # @response `201 Created` with the newly created claim object.
      #   Example:
      #     { "id": "claim_123", "status": "submitted", ... }
      # @response `422 Unprocessable Entity` if the parameters are invalid or business logic fails.
      #   Example:
      #     { "errors": ["Excessive claims detected."] }
      def create
        permitted_params = params.permit(:claim_type, :description, :amount_claimed)

        result = ::Claims::Create.call(
          customer_id: current_customer.id,
          **permitted_params,
          context: { actor_id: current_customer.id }
        )

        render json: result.value, status: 201
      end

      # Fetches a single claim for the current customer by its ID.
      #
      # @route GET /claims/:id
      # @permission read:claim
      #
      # @param id [String] The ID of the claim to fetch.
      # @param include_deleted [Boolean] Flag to include soft-deleted claims.
      #
      # @response `200 OK` with the claim object.
      #   Example:
      #     { "id": "claim_123", "status": "submitted", ... }
      # @response `404 Not Found` if the claim does not exist or does not belong to the customer.
      def show
        result = ::Claims::Fetch.call(
          customer_id: current_customer.id,
          claim_id: claim_id,
          include_deleted: include_deleted
        )

        render json: result.value, status: 200
      end

      # Updates the status of a claim.
      #
      # @route PATCH /claims/:id
      # @permission update:claim
      #
      # @param id [String] The ID of the claim to update.
      # @param status [String] The new status for the claim.
      #
      # @response `200 OK` with the updated claim object.
      #   Example:
      #     { "id": "claim_123", "status": "approved", ... }
      # @response `422 Unprocessable Entity` if the status is invalid or the update fails.
      #   Example:
      #     { "errors": ["Status is not included in the list."] }
      def update
        result = ::Claims::Update.call(
          customer_id: current_customer.id,
          claim_id: claim_id,
          status: params[:status],
          context: { actor_id: current_customer.id }
        )

        render json: result.value, status: 200
      end

      # Soft-deletes a claim.
      #
      # @route DELETE /claims/:id
      # @permission delete:claim
      #
      # @param id [String] The ID of the claim to delete.
      #
      # @response `200 OK` with a success message.
      #   Example:
      #     { "status": "deleted" }
      # @response `422 Unprocessable Entity` if the deletion fails.
      def destroy
        result = ::Claims::Delete.call(
          customer_id: current_customer.id,
          claim_id: claim_id,
          context: { actor_id: current_customer.id }
        )

        render json: { status: :deleted }, status: 200
      end

      private

      # Retrieves the claim ID from the request parameters.
      # @return [String] The claim ID.
      def claim_id
        params[:id]
      end

      # Determines whether soft-deleted claims should be included.
      # @return [Boolean] `true` if `include_deleted` is in the params and is a truthy value, otherwise `false`.
      def include_deleted
        ActiveModel::Type::Boolean.new.cast(params[:include_deleted])
      end
    end
  end
end
