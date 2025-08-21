# frozen_string_literal: true

require "base64"
require "json"
require "openssl"

# This module provides robust, cursor-based pagination capabilities for ActiveRecord models.
# It supports both PostgreSQL tuple comparison and a fallback for other adapters.
# It also includes HMAC-based signing to prevent cursor tampering.
#
# To use, include `CursorPagination` in your model and call `cursor_keys`.
#
# @example Basic usage
#   class Post < ApplicationRecord
#     include CursorPagination
#     cursor_keys :published_at, :id
#   end
#
#   # In a controller
#   posts = Post.after(params[:cursor]).limit(10)
#   next_cursor = posts.last&.cursor
module CursorPagination
  extend ActiveSupport::Concern

  DEFAULT_KEYS   = %i[created_at id].freeze
  DEFAULT_ORDERS = DEFAULT_KEYS.index_with { :asc }.freeze
  ISO8601_RE     = /\A\d{4}-\d{2}-\d{2}T/.freeze
  VERSION        = 1

  included do
    # @!attribute _cursor_keys
    #   @return [Array<Symbol>] The keys used for cursor-based pagination.
    # @!attribute _cursor_orders
    #   @return [Hash] The sort order for each key.
    class_attribute :_cursor_keys,   instance_writer: false, default: DEFAULT_KEYS
    class_attribute :_cursor_orders, instance_writer: false, default: DEFAULT_ORDERS
  end

  class_methods do
    # The secret key used for HMAC signing of cursors to prevent tampering.
    SECRET = Rails.application.credentials.dig(:cursor_secret) || ENV["CURSOR_SECRET"]

    # Configures the keys and their sort order for cursor pagination.
    #
    # @param keys [Array<Symbol>] A list of keys to use for the cursor. Defaults to ascending order.
    # @param kw_keys [Hash] A hash of keys and their explicit sort orders (`:asc` or `:desc`).
    # @return [Array<Symbol>] The configured cursor keys.
    #
    # @example Using a list of keys (all ascending)
    #   cursor_keys :published_at, :uuid
    #
    # @example Specifying sort order
    #   cursor_keys published_at: :desc, uuid: :asc
    def cursor_keys(*keys, **kw_keys)
      if keys.empty? && kw_keys.empty?
        _cursor_keys
      else
        orders               = kw_keys.presence || keys.index_with { :asc }
        self._cursor_keys    = orders.keys.map(&:to_sym)
        self._cursor_orders  = orders.transform_keys(&:to_sym)
        remove_instance_variable(:@_quoted_cols) if instance_variable_defined?(:@_quoted_cols)
      end
    end

    # Returns a scope for records that come after the given cursor.
    #
    # @param encoded_cursor [String] The Base64-encoded cursor string.
    # @return [ActiveRecord::Relation] The filtered relation.
    # @raise [BadRequestError] if the cursor is invalid.
    def after(encoded_cursor)  = where(build_where_clause(encoded_cursor, :after))

    # Returns a scope for records that come before the given cursor.
    #
    # @param encoded_cursor [String] The Base64-encoded cursor string.
    # @return [ActiveRecord::Relation] The filtered relation.
    # @raise [BadRequestError] if the cursor is invalid.
    def before(encoded_cursor) = where(build_where_clause(encoded_cursor, :before))

    # Applies a cursor to the current relation based on the `after` or `before` key in the params hash.
    #
    # @param params [Hash] The parameters hash, typically from a controller.
    # @return [ActiveRecord::Relation] The filtered relation, or `all` if no cursor is present.
    def apply_cursor(params = {})
      return after(params[:after])   if params[:after].present?
      return before(params[:before]) if params[:before].present?

      all
    end

    # Builds a paginated relation suitable for a Relay-style connection.
    #
    # @param params [Hash] The parameters hash, typically from a controller.
    # @param max_page_size [Integer] The maximum number of records to return.
    # @return [ActiveRecord::Relation] The paginated relation.
    def relay_connection(params = {}, max_page_size: 1_000)
      rel   = order_for_relay.apply_cursor(params)
      limit = params[:first] || params[:last]
      rel   = rel.limit(limit.to_i.clamp(1, max_page_size)) if limit
      rel
    end

    # Applies the default cursor order to the current relation.
    #
    # @return [ActiveRecord::Relation] The ordered relation.
    def order_for_relay
      order(_cursor_keys.index_with { |k| _cursor_orders[k] || :asc })
    end

    # Encodes a record or hash into a secure, Base64-encoded cursor string.
    #
    # @param record_or_hash [ApplicationRecord, Hash] The record or hash to encode.
    # @return [String, nil] The Base64-encoded cursor string, or `nil` if the input is blank.
    def encode_cursor(record_or_hash)
      data_hash = record_or_hash.is_a?(Hash) ? record_or_hash : build_payload(record_or_hash)
      return nil if data_hash.blank?

      payload = {
        v: VERSION,
        k: _cursor_keys,                                   # keys
        o: _cursor_keys.map { _cursor_orders[_1] || :asc }, # orders
        d: _cursor_keys.map { |k| data_hash[k.to_sym] }    # data
      }

      if SECRET.present?
        json          = payload.to_json
        payload[:s]   = OpenSSL::HMAC.hexdigest("SHA256", SECRET, json)
      end

      Base64.urlsafe_encode64(payload.to_json, padding: false)
    end

    # Decodes a Base64-encoded cursor string back into a hash of key-value pairs.
    #
    # @param encoded [String] The Base64-encoded cursor string.
    # @return [Hash] A hash containing the decoded cursor data.
    # @raise [BadRequestError] if the cursor is blank, has an unsupported version,
    #   has mismatched keys, or has an invalid signature.
    def decode_cursor(encoded)
      raise BadRequestError, "blank cursor" if encoded.blank?

      payload = JSON.parse(Base64.urlsafe_decode64(encoded))

      unless payload["v"] == VERSION
        return decode_cursor_v0(encoded) if payload["v"].nil?
        raise BadRequestError, "unsupported cursor version #{payload['v']}"
      end

      unless payload["k"] == _cursor_keys.map(&:to_s)
        raise BadRequestError,
              "cursor keys #{payload['k']} don't match server #{_cursor_keys}"
      end

      if SECRET.present?
        sig = payload["s"] or raise BadRequestError, "unsigned cursor"
        expected = OpenSSL::HMAC.hexdigest("SHA256", SECRET, payload.except("s").to_json)
        unless sig.bytesize == expected.bytesize &&
          ActiveSupport::SecurityUtils.secure_compare(sig, expected)
          raise BadRequestError, "cursor signature mismatch"
        end
      end

      payload["k"].zip(payload["d"]).to_h.transform_values do |v|
        iso8601_time?(v) ? Time.iso8601(v) : v
      end
    rescue ArgumentError, JSON::ParserError => e
      raise BadRequestError, e.message
    end

    # Builds the SQL `WHERE` clause for cursor-based pagination.
    # It uses tuple comparison for supported databases (PostgreSQL, MySQL 8+)
    # and falls back to a chained `OR` clause for others.
    #
    # @param encoded_cursor [String] The Base64-encoded cursor string.
    # @param direction [Symbol] The direction of pagination, `:after` or `:before`.
    # @return [String] The SQL `WHERE` clause.
    def build_where_clause(encoded_cursor, direction = :after)
      payload = decode_cursor(encoded_cursor)

      # Decide operator based on ASC/DESC vs requested direction
      op = _cursor_keys.map { |k|
        asc = _cursor_orders[k] != :desc
        (direction.to_sym == :after ? asc : !asc) ? ">" : "<"
      }.first

      # If DB supports tuple comparison (PostgreSQL, MySQL 8+):
      if ActiveRecord::Base.connection.adapter_name.in?(%w[PostgreSQL Mysql2])
        @_quoted_cols ||= _cursor_keys
                            .map { |c| connection.quote_column_name(c) }
                            .join(", ")
        binds        = _cursor_keys.map { |k| payload[k.to_s] }
        placeholders = [ "?" ] * _cursor_keys.size
        return sanitize_sql_array(
          [ "(#{@_quoted_cols}) #{op} (#{placeholders.join(', ')})", *binds ]
        )
      end

      # Fallback: chained OR comparison for adapters without tuple support
      build_chained_or(payload, direction)
    end

    private

    # Builds a chained `OR` SQL clause for databases that do not support tuple comparison.
    #
    # @param payload [Hash] The decoded cursor payload.
    # @param direction [Symbol] The pagination direction, `:after` or `:before`.
    # @return [String] The chained `OR` SQL clause.
    def build_chained_or(payload, direction)
      comparator_for = lambda do |key|
        asc = _cursor_orders[key] != :desc
        (direction.to_sym == :after ? asc : !asc) ? ">" : "<"
      end

      clauses = _cursor_keys.each_with_index.map do |k, idx|
        lhs = _cursor_keys[0..idx].map { |c| connection.quote_column_name(c) }.join(", ")
        rhs = _cursor_keys[0..idx].map { "?" }.join(", ")
        op  = comparator_for.call(k)
        "(#{lhs}) #{op} (#{rhs})"
      end

      binds = _cursor_keys.each_with_index.flat_map do |k, idx|
        _cursor_keys[0..idx].map { payload[_1.to_s] }
      end

      sanitize_sql_array([ clauses.join(" OR "), *binds ])
    end

    # Decodes a legacy version 0 cursor (without a header).
    #
    # @param encoded [String] The Base64-encoded cursor string.
    # @return [Hash] The decoded cursor data.
    # @raise [BadRequestError] if the legacy cursor is invalid.
    def decode_cursor_v0(encoded)
      data = JSON.parse(Base64.urlsafe_decode64(encoded))
      data.transform_values { |v| iso8601_time?(v) ? Time.iso8601(v) : v }
    rescue StandardError => e
      raise BadRequestError, "invalid legacy cursor: #{e.message}"
    end

    # Builds a payload hash from a given record using the configured cursor keys.
    #
    # @param record [ApplicationRecord] The record to build the payload from.
    # @return [Hash] The payload hash.
    def build_payload(record)
      _cursor_keys.index_with do |k|
        v = record.public_send(k)
        v.is_a?(Time) ? v.utc.iso8601(6) : v
      end
    end

    # Checks if a string has an ISO 8601 format.
    #
    # @param str [String] The string to check.
    # @return [Boolean] `true` if the string matches the ISO 8601 format, `false` otherwise.
    def iso8601_time?(str)
      str.is_a?(String) && str.match?(ISO8601_RE)
    end
  end

  # Encodes the current record into a cursor string.
  #
  # @return [String] The Base64-encoded cursor string for the current record.
  def cursor
    self.class.encode_cursor(self)
  end
end
