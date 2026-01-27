# frozen_string_literal: true

# Serializer for GeneratedPlanContent - handles complex nested JSON structure
# This serializer parses the JSON content from generated_plans.content field
# and structures it for API responses
class GeneratedPlanContentSerializer < ApplicationSerializer
  # Activity serializer for daily itinerary
  class ActivitySerializer < ApplicationSerializer
    fields :time, :name, :duration_minutes, :description
    fields :estimated_cost_usd, :estimated_cost_per_person_usd, :rating
    field :google_maps_url, if: ->(_, activity, _) { activity[:google_maps_url].present? }
  end

  # Restaurant serializer for meal recommendations
  class RestaurantSerializer < ApplicationSerializer
    fields :meal, :name, :cuisine, :estimated_cost_per_person_usd, :rating
    field :google_maps_url, if: ->(_, restaurant, _) { restaurant[:google_maps_url].present? }
  end

  # Daily itinerary serializer
  class DailyItinerarySerializer < ApplicationSerializer
    fields :day, :date

    field :activities do |daily_itinerary|
      ActivitySerializer.render_as_hash(daily_itinerary[:activities] || [])
    end

    field :restaurants do |daily_itinerary|
      RestaurantSerializer.render_as_hash(daily_itinerary[:restaurants] || [])
    end
  end

  # Hotel serializer
  class HotelSerializer < ApplicationSerializer
    fields :name, :location, :estimated_cost_per_night_usd, :rating
    field :google_maps_url, if: ->(_, hotel, _) { hotel[:google_maps_url].present? }
    field :description, if: ->(_, hotel, _) { hotel[:description].present? }
  end

  # Trip summary serializer
  class TripSummarySerializer < ApplicationSerializer
    fields :total_cost_usd, :cost_per_person_usd, :duration_days, :number_of_people
  end

  # Main content structure
  field :summary do |content|
    TripSummarySerializer.render_as_hash(content[:summary]) if content[:summary]
  end

  field :hotels do |content|
    HotelSerializer.render_as_hash(content[:hotels] || [])
  end

  field :daily_itinerary do |content|
    DailyItinerarySerializer.render_as_hash(content[:daily_itinerary] || [])
  end

  # Helper method to parse JSON content from GeneratedPlan model
  # Returns a hash with symbolized keys ready for serialization
  def self.parse_content(json_string)
    return nil if json_string.blank?

    JSON.parse(json_string, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse generated plan content: #{e.message}")
    nil
  end
end
