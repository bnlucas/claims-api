# frozen_string_literal: true

require "gaskit"

Gaskit.config do |c|
  c.debug = true
  c.context_provider = -> {
    {
      customer_id: RequestStore.store[:customer_id]
    }
  }
end

Gaskit.hooks.register(:after, :auditable) { |op, result:| Gaskit::Hooks::Auditable.after(op, result:) }
