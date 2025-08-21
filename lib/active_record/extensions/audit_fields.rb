# frozen_string_literal: true

# Extends ActiveRecord's `TableDefinition` DSL to support adding audit-related metadata fields.
#
# The `audit_fields` method adds standard user-scoped auditing columns to any table definition,
# typically used to record the UUIDs of the users responsible for creating, updating, or deleting
# a record. These fields support traceability in multi-user systems.
#
# Example usage in a migration:
#
#   create_table :posts, id: :uuid do |t|
#     t.string :title
#     t.audit_fields
#     t.timestamps with_deleted_at: true
#   end
#
# This will add the following nullable UUID columns:
# - `created_by`: who created the record
# - `updated_by`: who last updated the record
# - `deleted_by`: who deleted the record (optional, can be disabled)
#
# @see ActiveRecord::ConnectionAdapters::TableDefinition#timestamps
module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      # Adds standard audit metadata columns to the table definition.
      #
      # These fields are intended to store UUIDs referencing users (or actors) responsible for
      # changes to the row. All fields are nullable, allowing systems to populate them selectively.
      #
      # @example Add full audit fields to a table
      #   t.audit_fields
      #
      # @example Add only created_by and updated_by (no deleted_by)
      #   t.audit_fields(with_deleted_by: false)
      #
      # @param with_deleted_by [Boolean] whether to include the `deleted_by` column
      #   for tracking soft-deletion authorship. Defaults to `true`.
      # @return [void]
      def audit_fields(with_deleted_by: true, with_revoked_by: false)
        column(:created_by, :uuid, null: true)
        column(:updated_by, :uuid, null: true)
        column(:deleted_by, :uuid, null: true) if with_deleted_by
        column(:revoked_by, :uuid, null: true) if with_revoked_by
      end
    end
  end
end
