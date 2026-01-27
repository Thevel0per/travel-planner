# frozen_string_literal: true

# Serializer for UserPreferences resources
# Implements TypeSpec UserPreferences model from tsp/preferences.tsp
class UserPreferencesSerializer < ApplicationSerializer
  identifier :id

  fields :user_id, :budget, :accommodation, :activities, :eating_habits

  # Format timestamps as ISO 8601
  field :created_at do |preferences|
    preferences.created_at.iso8601
  end

  field :updated_at do |preferences|
    preferences.updated_at.iso8601
  end
end
