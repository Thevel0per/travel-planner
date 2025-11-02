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
    const :google_maps_url, T.nilable(String), default: nil # Google Maps URL for the location
  end

  # Restaurant recommendation for a meal
  class RestaurantSchema < T::Struct
    extend T::Sig

    const :meal, String # "breakfast", "lunch", "dinner"
    const :name, String
    const :cuisine, String
    const :estimated_cost_per_person_usd, Float
    const :rating, Float # 0.0-5.0
    const :google_maps_url, T.nilable(String), default: nil # Google Maps URL for the location
  end

  # Daily itinerary with activities and restaurant recommendations
  class DailyItinerarySchema < T::Struct
    extend T::Sig

    const :day, Integer # Day number (1, 2, 3, etc.)
    const :date, String # ISO 8601 date format (YYYY-MM-DD)
    const :activities, T::Array[ActivitySchema]
    const :restaurants, T::Array[RestaurantSchema]
  end

  # Hotel recommendation
  class HotelSchema < T::Struct
    extend T::Sig

    const :name, String
    const :location, String # Address or location description
    const :estimated_cost_per_night_usd, Float
    const :rating, Float # 0.0-5.0
    const :google_maps_url, T.nilable(String), default: nil # Google Maps URL for the hotel
    const :description, T.nilable(String), default: nil # Optional description
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
    const :hotels, T::Array[HotelSchema], default: [] # Recommended hotels
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

      hotels = if data[:hotels].is_a?(Array)
                 data[:hotels].map do |hotel_data|
                   HotelSchema.new(
                     name: hotel_data[:name],
                     location: hotel_data[:location],
                     estimated_cost_per_night_usd: hotel_data[:estimated_cost_per_night_usd].to_f,
                     rating: hotel_data[:rating].to_f,
                     google_maps_url: hotel_data[:google_maps_url] || nil,
                     description: hotel_data[:description] || nil
                   )
                 end
      else
                 []
      end

      daily_itinerary = data[:daily_itinerary].map do |day_data|
        activities = day_data[:activities].map do |activity_data|
          ActivitySchema.new(
            time: activity_data[:time],
            name: activity_data[:name],
            duration_minutes: activity_data[:duration_minutes],
            estimated_cost_usd: activity_data[:estimated_cost_usd].to_f,
            estimated_cost_per_person_usd: activity_data[:estimated_cost_per_person_usd].to_f,
            rating: activity_data[:rating].to_f,
            description: activity_data[:description],
            google_maps_url: activity_data[:google_maps_url] || nil
          )
        end

        restaurants = day_data[:restaurants].map do |restaurant_data|
          RestaurantSchema.new(
            meal: restaurant_data[:meal],
            name: restaurant_data[:name],
            cuisine: restaurant_data[:cuisine],
            estimated_cost_per_person_usd: restaurant_data[:estimated_cost_per_person_usd].to_f,
            rating: restaurant_data[:rating].to_f,
            google_maps_url: restaurant_data[:google_maps_url] || nil
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
        hotels:,
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
        hotels: hotels.map do |hotel|
          {
            name: hotel.name,
            location: hotel.location,
            estimated_cost_per_night_usd: hotel.estimated_cost_per_night_usd,
            rating: hotel.rating,
            google_maps_url: hotel.google_maps_url,
            description: hotel.description
          }
        end,
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
                description: activity.description,
                google_maps_url: activity.google_maps_url
              }
            end,
            restaurants: day.restaurants.map do |restaurant|
              {
                meal: restaurant.meal,
                name: restaurant.name,
                cuisine: restaurant.cuisine,
                estimated_cost_per_person_usd: restaurant.estimated_cost_per_person_usd,
                rating: restaurant.rating,
                google_maps_url: restaurant.google_maps_url
              }
            end
          }
        end
      }.to_json
    end
  end
end
