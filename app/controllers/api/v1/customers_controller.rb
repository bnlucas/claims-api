# frozen_string_literal: true

module Api
  module V1
    # CustomersController manages all API endpoints for customers.
    # It delegates business logic to `Customer` service objects.
    class CustomersController < ApplicationController
      # Enforces that requests to the `index` and `show` actions must have
      # a JWT with the "read:claim" scope.
      require_scope :index, "read:claim"
      require_scope :show,  "read:claim"

      # Retrieves a paginated list of customers.
      # The pagination is handled via a cursor-based approach.
      #
      # @param params [Hash] The request parameters.
      # @option params [Integer] :limit The number of records to return. Defaults to `PAGINATION_LIMIT`.
      # @option params [String] :cursor The pagination cursor for fetching the next page.
      # @option params [Boolean] :include_deleted A flag to include soft-deleted customers.
      # @return [JSON] A paginated list of customers.
      # @example GET /customers?limit=50&cursor=somecursor
      def index
        limit = (params[:limit].presence&.to_i || PAGINATION_LIMIT).clamp(1, MAX_PAGINATION_LIMIT)

        result = ::Customers::FetchAll.call(
          limit: limit,
          cursor: params[:cursor].presence,
          include_deleted: include_deleted
        )

        # The service now returns an ActiveRecord::Relation. `jsonapi_paginate`
        # will handle the pagination and cursor logic for us.
        response = jsonapi_paginate(result.value, limit: limit)
        render json: response, status: 200
      end

      # Retrieves a single customer by ID.
      #
      # @param params [Hash] The request parameters.
      # @option params [String] :id The ID of the customer to fetch.
      # @return [JSON] The requested customer object.
      # @raise [NotFoundError] If the customer is not found.
      # @example GET /customers/123e4567-e89b-12d3-a456-426614174000
      def show
        result = ::Customers::Fetch.call(
          customer_id: customer_id
        )

        render json: result.value, status: 200
      end

      private

      # Retrieves the customer ID from the request parameters.
      # @return [String] The customer ID.
      def customer_id
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
