# frozen_string_literal: true

class AuditLog < ApplicationRecord
  include CursorPagination

  # ----------------------------------------
  # Validations
  # ----------------------------------------
  validates :customer_id, presence: true
  validates :claim_id, presence: true
  validates :actor_id, presence: true
  validates :action, presence: true
  validates :details, presence: true

  # ----------------------------------------
  # Associations
  # ----------------------------------------
  belongs_to :customer, class_name: "Customer", foreign_key: "customer_id"
  belongs_to :claim, class_name: "Claim", foreign_key: "claim_id"

  def readonly?
    true
  end
end
