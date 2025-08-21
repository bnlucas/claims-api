# frozen_string_literal: true

module Claims
  # `Claims::Update` is a service object responsible for updating a claim's attributes.
  # It primarily handles updating the claim's status, ensuring that the provided status
  # is valid and that the claim belongs to the correct customer.
  class Update < ApplicationService
    use_hooks :auditable

    error :invalid_status, "Invalid status provided"

    # Updates a claim's status.
    #
    # @param customer_id [String] The ID of the customer who owns the claim.
    # @param claim_id [String] The ID of the claim to update.
    # @param status [String] The new status to be applied to the claim.
    # @return [Gaskit::ServiceResult] A successful result containing the updated `Claim` object,
    #   a failed result with an error message, or an exit signal if the status is invalid.
    def call(customer_id:, claim_id:, status:)
      result = ::Claims::Fetch.call(customer_id:, claim_id:)
      return result unless result.success?

      claim = result.value

      unless ::Claim::STATUSES.values.include?(status)
        exit(:invalid_status, "Invalid status: #{status}")
      end

      claim.update(status:)
      claim
    end
  end
end
