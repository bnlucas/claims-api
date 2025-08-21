# frozen_string_literal: true

module Claims
  class Create < ApplicationService
    use_hooks :auditable

    error :excessive_claims, "Excessive claims detected. Please contact support."

    def call(customer_id:, claim_type:, description:, amount_claimed:)
      exit(:excessive_claims) if excessive_claims?(customer_id)

      claim = ::Claim.new(
        customer_id:,
        claim_type:,
        description:,
        amount_claimed:
      )

      claim.is_duplicate = is_duplicate?(claim)
      claim.save!

      claim
    end

    private

    def excessive_claims?(customer_id)
      ::Claim.where(customer_id:)
             .where("created_at >= ?", 1.week.ago)
             .count >= 5
    end

    def is_duplicate?(new_claim)
      existing_claims = ::Claim.active
                               .where(customer_id: new_claim.customer_id, claim_type: new_claim.claim_type)
                               .where.not(id: new_claim.id)

      existing_claims.any? do |existing_claim|
        existing_claim.description.downcase.include?(new_claim.description.downcase) ||
          new_claim.description.downcase.include?(existing_claim.description.downcase)
      end
    end
  end
end
