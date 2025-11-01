# typed: strict
# frozen_string_literal: true

module TravelPlanGeneration
  # Validates input data before generating travel plans
  class InputValidator
    extend T::Sig

    sig { returns(Trip) }
    attr_reader :trip

    sig { returns(UserPreference) }
    attr_reader :user_preferences

    sig { returns(T::Array[Note]) }
    attr_reader :notes

    sig { returns(T::Array[String]) }
    attr_reader :errors

    sig do
      params(
        trip: Trip,
        user_preferences: UserPreference,
        notes: T::Array[Note]
      ).void
    end
    def initialize(trip:, user_preferences:, notes:)
      @trip = trip
      @user_preferences = user_preferences
      @notes = notes
      @errors = T.let([], T::Array[String])
    end

    # Validate all inputs
    sig { returns(T::Boolean) }
    def valid?
      @errors = []

      validate_trip
      validate_user_preferences
      validate_notes

      @errors.empty?
    end

    private

    sig { void }
    def validate_trip
      @errors << 'Trip destination is required' if trip.destination.blank?
      @errors << 'Trip start date is required' if trip.start_date.blank?
      @errors << 'Trip end date is required' if trip.end_date.blank?
      @errors << 'Number of people must be positive' if trip.number_of_people.nil? || trip.number_of_people <= 0

      if trip.start_date.present? && trip.end_date.present?
        if trip.end_date <= trip.start_date
          @errors << 'Trip end date must be after start date'
        end

        duration = calculate_duration
        @errors << 'Trip duration must be between 1 and 30 days' if duration < 1 || duration > 30
      end
    end

    sig { void }
    def validate_user_preferences
      # User preferences are optional but must be valid if present
      if user_preferences.budget.present? && !Enums::Budget.string_values.include?(user_preferences.budget)
        @errors << 'Invalid budget preference'
      end

      if user_preferences.accommodation.present? && !Enums::Accommodation.string_values.include?(user_preferences.accommodation)
        @errors << 'Invalid accommodation preference'
      end

      if user_preferences.eating_habits.present? && !Enums::EatingHabit.string_values.include?(user_preferences.eating_habits)
        @errors << 'Invalid eating habits preference'
      end
    end

    sig { void }
    def validate_notes
      # Notes are optional, just ensure array is not nil
      @errors << 'Notes must be an array' unless notes.is_a?(Array)
    end

    sig { returns(Integer) }
    def calculate_duration
      ((trip.end_date - trip.start_date).to_i + 1)
    end
  end
end

