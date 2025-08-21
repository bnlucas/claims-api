# frozen_string_literal: true

# The base class for all application models. It includes common concerns
# like `CursorPagination` and defines utility methods and scopes
# that are available to all models inheriting from it.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include CursorPagination

  class << self
    # Performs a fuzzy search on one or more columns using the `LIKE` or `ILIKE` operator.
    # This method is designed to be case-insensitive for PostgreSQL and case-sensitive
    # for other adapters.
    #
    # @param keys [Array<Symbol>] The column names to search within.
    # @param query [String] The search query string.
    # @return [ActiveRecord::Relation] A new relation with the fuzzy search conditions applied.
    # @raise [ArgumentError] if any of the specified `keys` do not exist as columns in the table.
    #
    # @example
    #   User.fuzzy_find([:first_name, :last_name], "John")
    #   #=> SELECT "users".* FROM "users" WHERE ("first_name" ILIKE '%John%' OR "last_name" ILIKE '%John%') ORDER BY "first_name" ASC
    def fuzzy_find(keys, query)
      return all if query.blank?

      keys = Array(keys).map(&:to_s)
      invalid_keys = keys - column_names
      raise ArgumentError, "columns #{invalid_keys.join(', ')} do not exist" unless invalid_keys.empty?

      pattern  = "%#{sanitize_sql_like(query)}%"
      operator = connection.adapter_name.match?(/postgres/i) ? "ILIKE" : "LIKE"

      conditions = keys.map do |key|
        "#{connection.quote_column_name(key)} #{operator} ?"
      end.join(" OR ")

      values = Array.new(keys.size, pattern)

      where(conditions, *values).order(keys.first)
    end
  end

  # A scope that filters records to the current authenticated customer.
  # This scope is available to models that have a `customer_id` column.
  #
  # @return [ActiveRecord::Relation] A relation filtered by the current customer's ID, or `all` if no customer is authenticated.
  def self.for_current_customer
    customer_id = AuthInfo.current.customer_id
    where(customer_id:) if column_names.include?("customer_id") && customer_id.present?
  end
end
