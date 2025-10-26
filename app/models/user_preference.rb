# typed: strict
# frozen_string_literal: true

class UserPreference < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: true
  validates :budget,
            inclusion: { in: Enums::Budget.string_values, allow_nil: true },
            if: -> { budget.present? }
  validates :accommodation,
            inclusion: { in: Enums::Accommodation.string_values, allow_nil: true },
            if: -> { accommodation.present? }
  validates :eating_habits,
            inclusion: { in: Enums::EatingHabit.string_values, allow_nil: true },
            if: -> { eating_habits.present? }
  validate :activities_valid

  private

  sig { void }
  def activities_valid
    return if activities.blank?

    activity_list = activities.split(',').map(&:strip)
    valid_activities = Enums::Activity.string_values

    invalid = activity_list.reject { |activity| valid_activities.include?(activity) }
    if invalid.any?
      errors.add(:activities, "contains invalid values: #{invalid.join(', ')}")
    end
  end
end
