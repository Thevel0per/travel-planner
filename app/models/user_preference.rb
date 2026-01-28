# typed: strict
# frozen_string_literal: true

class UserPreference < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :user

  # Valid preference values
  BUDGETS = %w[budget_conscious standard luxury].freeze
  ACCOMMODATIONS = %w[hotel airbnb hostel resort camping].freeze
  ACTIVITIES = %w[outdoors sightseeing cultural relaxation adventure nightlife shopping].freeze
  EATING_HABITS = %w[restaurants_only self_prepared mix].freeze

  # Validations
  validates :user_id, uniqueness: true
  validates :budget,
            inclusion: { in: BUDGETS, allow_nil: true },
            if: -> { budget.present? }
  validates :accommodation,
            inclusion: { in: ACCOMMODATIONS, allow_nil: true },
            if: -> { accommodation.present? }
  validates :eating_habits,
            inclusion: { in: EATING_HABITS, allow_nil: true },
            if: -> { eating_habits.present? }
  validate :activities_valid

  private

  sig { void }
  def activities_valid
    return if activities.blank?

    activity_list = activities.split(',').map(&:strip)

    invalid = activity_list.reject { |activity| ACTIVITIES.include?(activity) }
    if invalid.any?
      errors.add(:activities, "contains invalid values: #{invalid.join(', ')}")
    end
  end
end
