# typed: strict
# frozen_string_literal: true

require 'ostruct'

class GeneratedPlan < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :trip

  # Rails enum for status
  # Provides query methods: pending?, generating?, completed?, failed?
  # Provides bang methods: pending!, generating!, completed!, failed!
  # Provides scopes: GeneratedPlan.pending, GeneratedPlan.completed, etc.
  enum :status, {
    pending: 'pending',
    generating: 'generating',
    completed: 'completed',
    failed: 'failed'
  }, default: :pending

  # Validations
  validates :content, presence: true, if: :completed?
  validates :rating,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 },
            allow_nil: true
  validate :rating_only_for_completed

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }

  # Parse JSON content into a Ruby object with method access
  sig { returns(T.nilable(OpenStruct)) }
  def parsed_content
    return nil if content.blank?

    @parsed_content = T.let(@parsed_content, T.nilable(OpenStruct))
    @parsed_content ||= JSON.parse(content, object_class: OpenStruct)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse generated plan content: #{e.message}")
    nil
  end

  # Status transitions (Rails enum provides status query methods like pending?, generating?, etc.)
  sig { void }
  def mark_as_generating!
    generating!
  end

  sig { params(content_json: String).void }
  def mark_as_completed!(content_json)
    update!(status: :completed, content: content_json)
  end

  sig { void }
  def mark_as_failed!
    failed!
  end

  private

  sig { void }
  def rating_only_for_completed
    if rating.present? && !completed?
      errors.add(:rating, 'can only be set for completed plans')
    end
  end
end
