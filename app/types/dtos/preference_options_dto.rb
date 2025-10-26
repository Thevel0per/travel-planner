# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for preference options
  # Returns available values for each preference category
  # Used by GET /preferences/options endpoint
  class PreferenceOptionsDTO < T::Struct
    extend T::Sig
    include BaseDTO

    # Options structure with arrays of allowed values for each preference type
    const :budget, T::Array[String]
    const :accommodation, T::Array[String]
    const :activities, T::Array[String]
    const :eating_habits, T::Array[String]

    sig { returns(PreferenceOptionsDTO) }
    def self.all_options
      new(
        budget: Enums::Budget.string_values,
        accommodation: Enums::Accommodation.string_values,
        activities: Enums::Activity.string_values,
        eating_habits: Enums::EatingHabit.string_values
      )
    end
  end
end
