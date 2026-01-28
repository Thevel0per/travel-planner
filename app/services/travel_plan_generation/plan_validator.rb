# typed: strict
# frozen_string_literal: true

module TravelPlanGeneration
  # Validates generated travel plans for consistency
  # Plan should be a hash with symbolized keys containing:
  # - summary: { total_cost_usd, cost_per_person_usd, duration_days, number_of_people }
  # - hotels: [{ name, location, estimated_cost_per_night_usd, rating, ... }]
  # - daily_itinerary: [{ day, date, activities: [...], restaurants: [...] }]
  class PlanValidator
    extend T::Sig

    sig { returns(Trip) }
    attr_reader :trip

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :plan

    sig do
      params(
        trip: Trip,
        plan: T::Hash[Symbol, T.untyped]
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
      summary = plan[:summary]

      return errors << 'Missing summary' unless summary

      if summary[:duration_days] != expected_duration
        errors << "Duration mismatch: expected #{expected_duration} days, got #{summary[:duration_days]}"
      end

      if summary[:number_of_people] != trip.number_of_people
        errors << "Number of people mismatch: expected #{trip.number_of_people}, got #{summary[:number_of_people]}"
      end

      errors
    end

    sig { returns(T::Array[String]) }
    def validate_itinerary
      errors = []
      expected_duration = calculate_duration
      daily_itinerary = plan[:daily_itinerary]

      return errors << 'Missing daily_itinerary' unless daily_itinerary.is_a?(Array)

      if daily_itinerary.length != expected_duration
        errors << "Itinerary length mismatch: expected #{expected_duration} days, got #{daily_itinerary.length}"
      end

      errors
    end

    sig { returns(T::Array[String]) }
    def validate_daily_details
      errors = []
      daily_itinerary = plan[:daily_itinerary]

      return errors unless daily_itinerary.is_a?(Array)

      daily_itinerary.each_with_index do |day, index|
        errors.concat(validate_day(day, index))
      end

      errors
    end

    sig { params(day: T::Hash[Symbol, T.untyped], index: Integer).returns(T::Array[String]) }
    def validate_day(day, index)
      errors = []
      expected_day_number = index + 1

      # Validate day number
      if day[:day] != expected_day_number
        errors << "Day number mismatch on index #{index}: expected #{expected_day_number}, got #{day[:day]}"
      end

      # Validate date
      expected_date = (trip.start_date + index.days).to_s
      if day[:date] != expected_date
        errors << "Date mismatch for day #{day[:day]}: expected #{expected_date}, got #{day[:date]}"
      end

      # Ensure there are activities
      activities = day[:activities]
      if !activities.is_a?(Array) || activities.empty?
        errors << "Day #{day[:day]} has no activities"
      end

      # Validate ratings
      errors.concat(validate_activity_ratings(day))
      errors.concat(validate_restaurant_ratings(day))

      errors
    end

    sig { params(day: T::Hash[Symbol, T.untyped]).returns(T::Array[String]) }
    def validate_activity_ratings(day)
      errors = []
      activities = day[:activities]

      return errors unless activities.is_a?(Array)

      activities.each do |activity|
        rating = activity[:rating]
        if rating && (rating < 0.0 || rating > 5.0)
          errors << "Invalid rating for activity '#{activity[:name]}': #{rating}"
        end
      end

      errors
    end

    sig { params(day: T::Hash[Symbol, T.untyped]).returns(T::Array[String]) }
    def validate_restaurant_ratings(day)
      errors = []
      restaurants = day[:restaurants]

      return errors unless restaurants.is_a?(Array)

      restaurants.each do |restaurant|
        rating = restaurant[:rating]
        if rating && (rating < 0.0 || rating > 5.0)
          errors << "Invalid rating for restaurant '#{restaurant[:name]}': #{rating}"
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
