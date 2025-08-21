# frozen_string_literal: true

# Provides soft deletion functionality for ActiveRecord models.
# Instead of permanently deleting a record, this concern sets a `deleted_at`
# timestamp, allowing the record to be easily restored and kept for auditing.
# It also defines scopes to query for active or soft-deleted records.
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # Scope for records that have not been soft-deleted.
    scope :active,   -> { where(deleted_at: nil) }
    # Scope for records that have been soft-deleted.
    scope :inactive, -> { where.not(deleted_at: nil) }
  end

  # Soft-deletes the record by setting the `deleted_at` timestamp.
  # It prevents a second soft deletion and also sets an optional `active`
  # attribute to `false` if it exists.
  # @return [Boolean] `true` if the record was successfully updated, `false` otherwise.
  def soft_delete
    return if deleted?

    updates = { deleted_at: Time.current }
    updates[:active] = false if respond_to?(:active)

    update_columns(updates)
  end

  # Restores a soft-deleted record by setting `deleted_at` to `nil`.
  # It prevents an attempt to restore an active record.
  # @return [Boolean] `true` if the record was successfully updated, `false` otherwise.
  def restore!
    return if active?

    update_column(:deleted_at, nil)
  end

  # Checks if the record is currently active (not soft-deleted).
  # @return [Boolean] `true` if `deleted_at` is `nil`, `false` otherwise.
  def active?
    deleted_at.nil?
  end

  # Checks if the record has been soft-deleted.
  # @return [Boolean] `true` if `deleted_at` is not `nil`, `false` otherwise.
  def deleted?
    !active?
  end

  # An alias for the `deleted?` method.
  alias_method :inactive?, :deleted?
end
