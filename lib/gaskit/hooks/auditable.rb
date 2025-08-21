# frozen_string_literal: true

# lib/gaskit/hooks/auditable.rb
module Gaskit
  module Hooks
    module Auditable
      def self.after(op, result:, **_kwargs)
        return unless result.success?

        record = result.value

        case record
        when Claim
          AuditLog.create!(
            customer_id: record.customer_id,
            claim_id: record.id,
            actor_id: op.context[:actor_id],
            action: op.class.name,
            details: "Claim #{record.id} updated"
          )
        when Customer
          AuditLog.create!(
            customer_id: record.id,
            claim_id: nil,
            actor_id: op.context[:actor_id],
            action: op.class.name,
            details: "Customer #{record.id} updated"
          )
        end
      rescue => e
        op.logger.error("Failed to create audit log: #{e.message}")
      end
    end
  end
end
