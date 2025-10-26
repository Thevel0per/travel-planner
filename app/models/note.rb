# typed: strict
# frozen_string_literal: true

class Note < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :trip

  # Validations
  validates :content, presence: true, length: { maximum: 10_000 }

  # Scopes
  scope :ordered, -> { order(created_at: :asc) }
end
