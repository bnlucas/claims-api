# frozen_string_literal: true

module Claims
  # `Claims::Delete` is a service object responsible for soft-deleting a claim.
  # Instead of permanent deletion, it marks the claim as inactive for auditing
  # and potential restoration.
  class Delete < ApplicationService
    use_hooks :auditable

    # Soft-deletes a claim by calling the `soft_delete` method on the `Claim` model.
    # It first fetches the claim to ensure it exists and belongs to the specified customer.
    #
    # @param customer_id [String] The ID of the customer who owns the claim.
    # @param claim_id [String] The ID of the claim to be soft-deleted.
    # @return [Gaskit::ServiceResult] A successful result containing the soft-deleted `Claim` object,
    #   or a failed result if the claim is not found or the deletion fails.
    def call(customer_id:, claim_id:)
      result = ::Claims::Fetch.call(customer_id:, claim_id:)
      return result unless result.success?

      claim = result.value
      claim.soft_delete

      claim
    end
  end
end
