# typed: strict
# frozen_string_literal: true

module Commands
  # Command Model for creating or updating user preferences
  # Used by PUT/PATCH /preferences endpoint
  # All fields are optional (partial updates allowed)
  # Derived from: user_preferences table (subset of fields)
  class PreferencesUpdateCommand < T::Struct
    include BaseDTO
    extend T::Sig

    const :budget, T.nilable(String), default: nil # One of: 'budget_conscious', 'standard', 'luxury'
    const :accommodation, T.nilable(String), default: nil # One of: 'hotel', 'airbnb', 'hostel', 'resort', 'camping'
    const :activities, T.nilable(String), default: nil # Comma-separated string of activity values
    const :eating_habits, T.nilable(String), default: nil # One of: 'restaurants_only', 'self_prepared', 'mix'

    sig { params(params: T::Hash[T.untyped, T.untyped]).returns(PreferencesUpdateCommand) }
    def self.from_params(params)
      preferences_params = params[:preferences] || params
      new(
        budget: preferences_params[:budget],
        accommodation: preferences_params[:accommodation],
        activities: preferences_params[:activities],
        eating_habits: preferences_params[:eating_habits]
      )
    end

    sig { params(original_params: T::Hash[T.untyped, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
    def to_model_attributes(original_params = {})
      attributes = {}
      preferences_params = original_params[:preferences] || original_params

      # Only include attributes that were explicitly submitted in the form
      # Empty strings from unselected dropdowns are converted to nil and excluded
      # This preserves existing values for fields that weren't submitted
      if preferences_params.key?(:budget)
        attributes[:budget] = budget.presence
      end
      if preferences_params.key?(:accommodation)
        attributes[:accommodation] = accommodation.presence
      end
      if preferences_params.key?(:activities)
        attributes[:activities] = activities.presence
      end
      if preferences_params.key?(:eating_habits)
        attributes[:eating_habits] = eating_habits.presence
      end
      attributes
    end
  end
end
