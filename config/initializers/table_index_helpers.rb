# frozen_string_literal: true

# Provides helper methods for adding and removing consistently named indexes
# across migrations, including client-scoped indexes, soft-delete indexes,
# and general-purpose abbreviated name indexes that respect Postgres's 63-character limit.
module TableIndexHelpers
  CLIENT_SCOPE_COLUMNS = %i[client_id user_id].freeze

  MAX_NAME_LENGTH = 63

  COLUMN_ABBREVIATIONS = {
    customer_id: :usrid,
    created_at: :crt,
    updated_at: :upd,
    deleted_at: :del
  }.freeze

  private_constant :CLIENT_SCOPE_COLUMNS
  private_constant :MAX_NAME_LENGTH
  private_constant :COLUMN_ABBREVIATIONS

  # Adds an index with a generated name based on table, columns, and uniqueness.
  #
  # @param table [Symbol, String] the table name
  # @param columns [Symbol, String, Array<Symbol,String>] the indexed columns
  # @param unique [Boolean] whether the index should be unique
  # @param options [Hash] any additional options passed to `add_index`
  # @return [void]
  def add_named_index(table, columns = [], unique: false, **options)
    name, columns = prepare_named_index(table, columns, unique: unique)
    add_index(table, columns, **options.merge(name: name, unique: unique))
  end

  # Removes an index using a generated name.
  #
  # @param table [Symbol, String] the table name
  # @param columns [Symbol, String, Array<Symbol,String>] the indexed columns
  # @param unique [Boolean] whether the index was unique
  # @param options [Hash] any additional options passed to `remove_index`
  # @return [void]
  def remove_named_index(table, columns = [], unique: false, **options)
    name, columns = prepare_named_index(table, columns, unique: unique)
    remove_index(table, columns, **options.merge(name: name))
  end

  # Adds an index scoped to `deleted_at` and optional additional columns.
  #
  # @param table [Symbol, String] the table name
  # @param columns [Symbol, String, Array<Symbol,String>] additional columns
  # @param name [String, nil] optional custom name
  # @return [void]
  def add_deleted_at_index(table, columns = [], name: nil)
    name, columns = prepare_deleted_at_index(table, columns, name: name)
    add_index(table, columns, name: name)
  end

  # Removes a previously created deleted-at-based index.
  #
  # @param table [Symbol, String] the table name
  # @param columns [Symbol, String, Array<Symbol,String>] additional columns
  # @param name [String, nil] optional custom name
  # @return [void]
  def remove_deleted_at_index(table, columns = [], name: nil)
    name, = prepare_deleted_at_index(table, columns, name: name)
    remove_index(table, name)
  end

  private

  # Ensures the table includes a `deleted_at` column.
  #
  # @param table [Symbol, String]
  # @raise [ArgumentError] if the column does not exist
  # @return [void]
  def guard_deleted_at!(table)
    return if column_exists?(table, :deleted_at)

    raise ArgumentError, "Table #{table} must include a `deleted_at` column to use this index helper"
  end

  # Normalizes a list of columns into a symbolized, deduplicated array.
  #
  # @param columns [Symbol, String, Array<Symbol,String>]
  # @return [Array<Symbol>]
  def normalize_columns(columns)
    Array(columns).uniq.map(&:to_sym)
  end

  # Prepares the index name and columns for a generic named index.
  #
  # @param table [Symbol, String]
  # @param columns [Symbol, String, Array<Symbol,String>]
  # @param unique [Boolean]
  # @return [Array<(String, Array<Symbol>)]]
  def prepare_named_index(table, columns, unique: false)
    index_columns = normalize_columns(columns)
    index_name = build_index_name(table, index_columns, unique: unique)

    [ index_name, index_columns ]
  end

  # Prepares the index name and columns for a deleted-at scoped index.
  #
  # @param table [Symbol, String]
  # @param columns [Symbol, String, Array<Symbol,String>]
  # @param name [String, nil]
  # @return [Array<(String, Array<Symbol>)]]
  def prepare_deleted_at_index(table, columns, name: nil)
    guard_deleted_at!(table)

    index_columns = ([ :deleted_at ] + normalize_columns(columns)).uniq
    index_name = name || build_index_name(table, index_columns)

    [ index_name, index_columns ]
  end

  # Builds a consistent index name, abbreviating known columns and appending a digest if too long.
  #
  # @param table [Symbol, String]
  # @param columns [Array<Symbol>]
  # @param unique [Boolean]
  # @return [String] the generated index name
  def build_index_name(table, columns, unique: false)
    abbr_columns = columns.map { |column| COLUMN_ABBREVIATIONS[column] || column }
    prefix = unique ? "uniq" : "idx"

    index_name = [ prefix, table, "on", *abbr_columns ].join("_")
    return index_name if index_name.length <= MAX_NAME_LENGTH

    digest = Digest::MD5.hexdigest(index_name)[0, 8]
    "#{index_name[0...(MAX_NAME_LENGTH - 9)]}_#{digest}"
  end
end

ActiveRecord::Migration.prepend(TableIndexHelpers)
