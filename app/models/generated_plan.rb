# typed: strict
# frozen_string_literal: true

class GeneratedPlan < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :trip

  # Validations
  validates :status, presence: true, inclusion: { in: Enums::GeneratedPlanStatus.string_values }
  validates :content, presence: true, if: -> { status == 'completed' }
  validates :rating,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 },
            allow_nil: true
  validate :rating_only_for_completed

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status:) if status.present? }

  # Status transitions
  sig { void }
  def mark_as_generating!
    update!(status: 'generating')
  end

  sig { params(content_json: String).void }
  def mark_as_completed!(content_json)
    update!(status: 'completed', content: content_json)
  end

  sig { void }
  def mark_as_failed!
    update!(status: 'failed')
  end

  private

  sig { void }
  def rating_only_for_completed
    if rating.present? && status != 'completed'
      errors.add(:rating, 'can only be set for completed plans')
    end
  end
end
