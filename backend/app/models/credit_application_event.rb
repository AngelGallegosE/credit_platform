class CreditApplicationEvent < ApplicationRecord
  belongs_to :credit_application

  # Validaciones
  validates :event_type, presence: true
  validates :metadata, presence: true

  # Scopes útiles
  scope :created, -> { where(event_type: "created") }
  scope :updated, -> { where(event_type: "updated") }
  scope :deleted, -> { where(event_type: "deleted") }
  scope :recent, -> { order(created_at: :desc) }
end
