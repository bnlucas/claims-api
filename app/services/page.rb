# frozen_string_literal: true

Page = Struct.new(
  :records,      # Array<ActiveRecord::Base>
  :next_cursor,  # String | nil
  :prev_cursor,  # String | nil
  keyword_init: true
) do
  delegate :each, :map, :size, :empty?, to: :records
end
