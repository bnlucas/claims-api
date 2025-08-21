# frozen_string_literal: true

require "yaml"

module RoleScopes
  def self.for(role)
    @scopes ||= YAML.load_file(Rails.root.join("config", "role_scopes.yml")).with_indifferent_access.freeze
    @scopes[role.to_s] || []
  end
end
