# frozen_string_literal: true

module Claims
  # `Claims::Fetch` is a service object responsible for fetching a single
  # claim by its ID. It ensures the claim belongs to the specified customer
  # and provides an option to include soft-deleted records.
  class Fetch < ApplicationService
    error :not_found, "Claim not found"

    # Fetches a claim for a given customer and claim ID.
    #
    # @param customer_id [String] The ID of the customer who owns the claim.
    # @param claim_id [String] The ID of the claim to fetch.
    # @param include_deleted [Boolean] A flag to include soft-deleted claims in the search.
    #   Defaults to `false`.
    # @return [Gaskit::ServiceResult] A successful result containing the `Claim` object
    #   if found, or a failed result if the claim is not found.
    def call(customer_id:, claim_id:, include_deleted: false)
      scope = ::Claim.where(customer_id:, id: claim_id)
      scope = scope.active unless include_deleted

      claim = scope.first

      return claim if claim
      exit(:not_found)
    end
  end
end
