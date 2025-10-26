# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for UserPreferences resource
  # Represents user travel preferences as returned by the API
  # Derived from: user_preferences table
  class UserPreferencesDTO < T::Struct
    extend T::Sig
    include BaseDTO

    # All attributes from user_preferences table
    const :id, Integer
    const :user_id, Integer
    const :budget, T.nilable(String) # One of: 'budget_conscious', 'standard', 'luxury'
    const :accommodation, T.nilable(String) # One of: 'hotel', 'airbnb', 'hostel', 'resort', 'camping'
    const :activities, T.nilable(String) # Comma-separated string of activity values
    const :eating_habits, T.nilable(String) # One of: 'restaurants_only', 'self_prepared', 'mix'
    const :created_at, String # ISO 8601 datetime format
    const :updated_at, String # ISO 8601 datetime format

    sig { params(preferences: UserPreference).returns(UserPreferencesDTO) }
    def self.from_model(preferences)
      new(
        id: preferences.id,
        user_id: preferences.user_id,
        budget: preferences.budget,
        accommodation: preferences.accommodation,
        activities: preferences.activities,
        eating_habits: preferences.eating_habits,
        created_at: preferences.created_at.iso8601,
        updated_at: preferences.updated_at.iso8601
      )
    end
  end
end
