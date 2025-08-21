# frozen_string_literal: true

module Customers
  # `Customers::Fetch` is a service object that fetches a single customer
  # by their ID. It provides an option to include soft-deleted customers in the search.
  class Fetch < ApplicationService
    use_contract :service
    error :not_found, "Customer not found"

    # Fetches a customer by ID.
    #
    # @param customer_id [String] The ID of the customer to fetch.
    # @param include_deleted [Boolean] A flag to include soft-deleted customers in the search.
    #   Defaults to `false`.
    # @return [Gaskit::ServiceResult] A successful result containing the `Customer` object
    #   if found, or a failed result with a `:not_found` error.
    def call(customer_id:, include_deleted: false)
      scope = Customer.where(id: customer_id)
      scope = scope.active unless include_deleted

      customer = scope.first

      return customer if customer
      exit(:not_found)
    end
  end
end
