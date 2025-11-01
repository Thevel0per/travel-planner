# typed: strict
# frozen_string_literal: true

module TravelPlanGeneration
  # Validates generated travel plans for consistency
  class PlanValidator
    extend T::Sig

    sig { returns(Trip) }
    attr_reader :trip

    sig { returns(Schemas::GeneratedPlanContent) }
    attr_reader :plan

    sig do
      params(
        trip: Trip,
        plan: Schemas::GeneratedPlanContent
      ).void
    end
    def initialize(trip:, plan:)
      @trip = trip
      @plan = plan
    end

    # Validate the generated plan
    sig { returns(T::Array[String]) }
    def validate
      errors = []

      errors.concat(validate_summary)
      errors.concat(validate_itinerary)
      errors.concat(validate_daily_details)

      errors
    end

    private

    sig { returns(T::Array[String]) }
    def validate_summary
      errors = []
      expected_duration = calculate_duration

      if plan.summary.duration_days != expected_duration
        errors << "Duration mismatch: expected #{expected_duration} days, got #{plan.summary.duration_days}"
      end

      if plan.summary.number_of_people != trip.number_of_people
        errors << "Number of people mismatch: expected #{trip.number_of_people}, got #{plan.summary.number_of_people}"
      end

      errors
    end

    sig { returns(T::Array[String]) }
    def validate_itinerary
      errors = []
      expected_duration = calculate_duration

      if plan.daily_itinerary.length != expected_duration
        errors << "Itinerary length mismatch: expected #{expected_duration} days, got #{plan.daily_itinerary.length}"
      end

      errors
    end

    sig { returns(T::Array[String]) }
    def validate_daily_details
      errors = []

      plan.daily_itinerary.each_with_index do |day, index|
        errors.concat(validate_day(day, index))
      end

      errors
    end

    sig { params(day: Schemas::DailyItinerarySchema, index: Integer).returns(T::Array[String]) }
    def validate_day(day, index)
      errors = []
      expected_day_number = index + 1

      # Validate day number
      if day.day != expected_day_number
        errors << "Day number mismatch on index #{index}: expected #{expected_day_number}, got #{day.day}"
      end

      # Validate date
      expected_date = (trip.start_date + index.days).to_s
      if day.date != expected_date
        errors << "Date mismatch for day #{day.day}: expected #{expected_date}, got #{day.date}"
      end

      # Ensure there are activities
      if day.activities.empty?
        errors << "Day #{day.day} has no activities"
      end

      # Validate ratings
      errors.concat(validate_activity_ratings(day))
      errors.concat(validate_restaurant_ratings(day))

      errors
    end

    sig { params(day: Schemas::DailyItinerarySchema).returns(T::Array[String]) }
    def validate_activity_ratings(day)
      errors = []

      day.activities.each do |activity|
        if activity.rating < 0.0 || activity.rating > 5.0
          errors << "Invalid rating for activity '#{activity.name}': #{activity.rating}"
        end
      end

      errors
    end

    sig { params(day: Schemas::DailyItinerarySchema).returns(T::Array[String]) }
    def validate_restaurant_ratings(day)
      errors = []

      day.restaurants.each do |restaurant|
        if restaurant.rating < 0.0 || restaurant.rating > 5.0
          errors << "Invalid rating for restaurant '#{restaurant.name}': #{restaurant.rating}"
        end
      end

      errors
    end

    sig { returns(Integer) }
    def calculate_duration
      ((trip.end_date - trip.start_date).to_i + 1)
    end
  end
end

