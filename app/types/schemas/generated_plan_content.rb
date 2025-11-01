# typed: strict
# frozen_string_literal: true

module Schemas
  # Schema types for the structured JSON content of generated travel plans
  # These types represent the AI-generated plan structure returned by the API

  # Activity within a day's itinerary
  class ActivitySchema < T::Struct
    extend T::Sig

    const :time, String # e.g., "10:00 AM"
    const :name, String
    const :duration_minutes, Integer
    const :estimated_cost_usd, Float
    const :estimated_cost_per_person_usd, Float
    const :rating, Float # 0.0-5.0
    const :description, String
  end

  # Restaurant recommendation for a meal
  class RestaurantSchema < T::Struct
    extend T::Sig

    const :meal, String # "breakfast", "lunch", "dinner"
    const :name, String
    const :cuisine, String
    const :estimated_cost_per_person_usd, Float
    const :rating, Float # 0.0-5.0
  end

  # Daily itinerary with activities and restaurant recommendations
  class DailyItinerarySchema < T::Struct
    extend T::Sig

    const :day, Integer # Day number (1, 2, 3, etc.)
    const :date, String # ISO 8601 date format (YYYY-MM-DD)
    const :activities, T::Array[ActivitySchema]
    const :restaurants, T::Array[RestaurantSchema]
  end

  # Summary information for the entire trip
  class TripSummarySchema < T::Struct
    extend T::Sig

    const :total_cost_usd, Float
    const :cost_per_person_usd, Float
    const :duration_days, Integer
    const :number_of_people, Integer
  end

  # Complete generated plan content structure
  # This is the top-level structure stored in generated_plans.content
  class GeneratedPlanContent < T::Struct
    extend T::Sig

    const :summary, TripSummarySchema
    const :daily_itinerary, T::Array[DailyItinerarySchema]

    sig { params(json_string: String).returns(GeneratedPlanContent) }
    def self.from_json(json_string)
      data = JSON.parse(json_string, symbolize_names: true)

      summary = TripSummarySchema.new(
        total_cost_usd: data[:summary][:total_cost_usd].to_f,
        cost_per_person_usd: data[:summary][:cost_per_person_usd].to_f,
        duration_days: data[:summary][:duration_days],
        number_of_people: data[:summary][:number_of_people]
      )

      daily_itinerary = data[:daily_itinerary].map do |day_data|
        activities = day_data[:activities].map do |activity_data|
          ActivitySchema.new(
            time: activity_data[:time],
            name: activity_data[:name],
            duration_minutes: activity_data[:duration_minutes],
            estimated_cost_usd: activity_data[:estimated_cost_usd].to_f,
            estimated_cost_per_person_usd: activity_data[:estimated_cost_per_person_usd].to_f,
            rating: activity_data[:rating].to_f,
            description: activity_data[:description]
          )
        end

        restaurants = day_data[:restaurants].map do |restaurant_data|
          RestaurantSchema.new(
            meal: restaurant_data[:meal],
            name: restaurant_data[:name],
            cuisine: restaurant_data[:cuisine],
            estimated_cost_per_person_usd: restaurant_data[:estimated_cost_per_person_usd].to_f,
            rating: restaurant_data[:rating].to_f
          )
        end

        DailyItinerarySchema.new(
          day: day_data[:day],
          date: day_data[:date],
          activities:,
          restaurants:
        )
      end

      new(
        summary:,
        daily_itinerary:
      )
    end

    sig { returns(String) }
    def to_json_string
      {
        summary: {
          total_cost_usd: summary.total_cost_usd,
          cost_per_person_usd: summary.cost_per_person_usd,
          duration_days: summary.duration_days,
          number_of_people: summary.number_of_people
        },
        daily_itinerary: daily_itinerary.map do |day|
          {
            day: day.day,
            date: day.date,
            activities: day.activities.map do |activity|
              {
                time: activity.time,
                name: activity.name,
                duration_minutes: activity.duration_minutes,
                estimated_cost_usd: activity.estimated_cost_usd,
                estimated_cost_per_person_usd: activity.estimated_cost_per_person_usd,
                rating: activity.rating,
                description: activity.description
              }
            end,
            restaurants: day.restaurants.map do |restaurant|
              {
                meal: restaurant.meal,
                name: restaurant.name,
                cuisine: restaurant.cuisine,
                estimated_cost_per_person_usd: restaurant.estimated_cost_per_person_usd,
                rating: restaurant.rating
              }
            end
          }
        end
      }.to_json
    end
  end
end
