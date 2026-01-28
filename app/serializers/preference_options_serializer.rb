# frozen_string_literal: true

# Serializer for PreferenceOptions
# Returns available values for each preference category
# Implements TypeSpec PreferenceOptions model from tsp/preferences.tsp
class PreferenceOptionsSerializer < ApplicationSerializer
  # This serializer works with a plain hash object, not an ActiveRecord model
  # The hash should contain arrays for: budget, accommodation, activities, eating_habits

  field :budget
  field :accommodation
  field :activities
  field :eating_habits

  class << self
    # Returns all available preference options from UserPreference model
    # @return [Hash] Hash containing all preference options
    def all_options
      {
        budget: UserPreference::BUDGETS,
        accommodation: UserPreference::ACCOMMODATIONS,
        activities: UserPreference::ACTIVITIES,
        eating_habits: UserPreference::EATING_HABITS
      }
    end
  end
end
