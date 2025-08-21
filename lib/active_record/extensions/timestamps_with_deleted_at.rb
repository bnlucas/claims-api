# frozen_string_literal: true

# Extends ActiveRecord's `TableDefinition#timestamps` to also include a `deleted_at` column
# for soft-deletion tracking. This ensures every table that uses `timestamps` will also gain
# `deleted_at`, allowing consistent use of soft-delete logic and scoped indexes.
#
# This override aliases the original `timestamps` method to preserve default Rails behavior
# and appends `deleted_at` as a nullable datetime column.
module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      # Alias the original `timestamps` method so we can wrap it
      alias_method :original_timestamps, :timestamps

      # Adds standard `created_at` and `updated_at` columns.
      # Optionally adds `deleted_at` for soft-deletion tracking.
      #
      # @param args [Array] standard timestamp args (e.g., precision)
      # @param with_deleted_at [Boolean] whether to include `deleted_at`, defaults to `true`
      # @param options [Hash] options passed to timestamps
      # @return [void]
      def timestamps(*args, with_deleted_at: true, with_revoked_at: false, **options)
        original_timestamps(*args, **options)
        column(:deleted_at, :datetime, null: true) if with_deleted_at
        column(:revoked_at, :datetime, null: true) if with_revoked_at
      end
    end
  end
end
