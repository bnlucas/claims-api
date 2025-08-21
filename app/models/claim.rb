# frozen_string_literal: true

class Claim < ApplicationRecord
  include CursorPagination
  include SoftDeletable

  # ----------------------------------------
  # Enums
  # ----------------------------------------
  STATUSES = {
    submitted: "submitted",
    processing: "processing",
    approved: "approved",
    rejected: "rejected",
  }.freeze

  # ----------------------------------------
  # Attributes
  # ----------------------------------------
  attribute :status, :string, default: "submitted"
  attribute :is_duplicate, :boolean, default: false
  attribute :amount_claimed, :decimal, default: 0.0

  # ----------------------------------------
  # Validations
  # ----------------------------------------
  validates :customer_id, presence: true
  validates :claim_type, presence: true
  validates :description, presence: true
  validates :amount_claimed, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES.values }

  # ----------------------------------------
  # Associations
  # ----------------------------------------
  belongs_to :customer, class_name: "Customer", foreign_key: "customer_id"
  has_many :audit_logs, class_name: "AuditLog", foreign_key: "claim_id"

  # ----------------------------------------
  # Scopes
  # ----------------------------------------
  scope :duplicates, -> { where(is_duplicate: true) }
  scope :submitted, -> { where(status: STATUSES[:submitted]) }
  scope :approved, -> { where(status: STATUSES[:approved]) }
  scope :denied, -> { where(status: STATUSES[:denied]) }
end
