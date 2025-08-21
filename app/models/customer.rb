# frozen_string_literal: true

class Customer < ApplicationRecord
  include SoftDeletable

  # ----------------------------------------
  # Enums
  # ----------------------------------------
  enum status: {
    active: "active",
    inactive: "inactive",
    suspended: "suspended"
  }, _suffix: true

  # ----------------------------------------
  # Validations
  # ----------------------------------------
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :status, presence: true

  # ----------------------------------------
  # Associations
  # ----------------------------------------
  has_many :claims, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  def active?
    status == "active"
  end
end
