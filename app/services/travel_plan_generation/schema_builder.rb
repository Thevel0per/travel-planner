# typed: strict
# frozen_string_literal: true

module TravelPlanGeneration
  # Builds JSON Schema for AI travel plan generation
  class SchemaBuilder
    extend T::Sig

    # Build JSON Schema for structured output matching GeneratedPlanContent
    sig { returns(T::Hash[String, T.untyped]) }
    def self.build
      {
        'type' => 'object',
        'properties' => {
          'summary' => summary_schema,
          'hotels' => hotels_schema,
          'daily_itinerary' => daily_itinerary_schema
        },
        'required' => [ 'summary', 'hotels', 'daily_itinerary' ],
        'additionalProperties' => false
      }
    end

    sig { returns(T::Hash[String, T.untyped]) }
    def self.summary_schema
      {
        'type' => 'object',
        'properties' => {
          'total_cost_usd' => { 'type' => 'number', 'description' => 'Total estimated cost for all people' },
          'cost_per_person_usd' => { 'type' => 'number', 'description' => 'Cost per person' },
          'duration_days' => { 'type' => 'integer', 'description' => 'Number of days' },
          'number_of_people' => { 'type' => 'integer', 'description' => 'Number of travelers' }
        },
        'required' => [ 'total_cost_usd', 'cost_per_person_usd', 'duration_days', 'number_of_people' ],
        'additionalProperties' => false
      }
    end

    sig { returns(T::Hash[String, T.untyped]) }
    def self.daily_itinerary_schema
      {
        'type' => 'array',
        'items' => {
          'type' => 'object',
          'properties' => {
            'day' => { 'type' => 'integer', 'description' => 'Day number (1, 2, 3, etc.)' },
            'date' => { 'type' => 'string', 'description' => 'Date in YYYY-MM-DD format' },
            'activities' => activities_schema,
            'restaurants' => restaurants_schema
          },
          'required' => [ 'day', 'date', 'activities', 'restaurants' ],
          'additionalProperties' => false
        }
      }
    end

    sig { returns(T::Hash[String, T.untyped]) }
    def self.activities_schema
      {
        'type' => 'array',
        'items' => {
          'type' => 'object',
          'properties' => {
            'time' => { 'type' => 'string', 'description' => 'Start time (e.g., "10:00 AM")' },
            'name' => { 'type' => 'string', 'description' => 'Activity name' },
            'duration_minutes' => { 'type' => 'integer', 'description' => 'Duration in minutes' },
            'estimated_cost_usd' => { 'type' => 'number', 'description' => 'Total cost for all people' },
            'estimated_cost_per_person_usd' => { 'type' => 'number', 'description' => 'Cost per person' },
            'rating' => { 'type' => 'number', 'description' => 'Rating from 0.0 to 5.0' },
            'description' => { 'type' => 'string', 'description' => 'Activity description' },
            'google_maps_url' => { 'type' => [ 'string', 'null' ], 'description' => 'Google Maps URL for the location (optional, can be null)' }
          },
          'required' => [ 'time', 'name', 'duration_minutes', 'estimated_cost_usd', 'estimated_cost_per_person_usd', 'rating', 'description', 'google_maps_url' ],
          'additionalProperties' => false
        }
      }
    end

    sig { returns(T::Hash[String, T.untyped]) }
    def self.hotels_schema
      {
        'type' => 'array',
        'items' => {
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string', 'description' => 'Hotel name' },
            'location' => { 'type' => 'string', 'description' => 'Hotel address or location description' },
            'estimated_cost_per_night_usd' => { 'type' => 'number', 'description' => 'Cost per night in USD' },
            'rating' => { 'type' => 'number', 'description' => 'Rating from 0.0 to 5.0' },
            'google_maps_url' => { 'type' => [ 'string', 'null' ], 'description' => 'Google Maps URL for the hotel location (optional, can be null)' },
            'description' => { 'type' => [ 'string', 'null' ], 'description' => 'Optional hotel description (can be null)' }
          },
          'required' => [ 'name', 'location', 'estimated_cost_per_night_usd', 'rating', 'google_maps_url', 'description' ],
          'additionalProperties' => false
        }
      }
    end

    sig { returns(T::Hash[String, T.untyped]) }
    def self.restaurants_schema
      {
        'type' => 'array',
        'items' => {
          'type' => 'object',
          'properties' => {
            'meal' => { 'type' => 'string', 'description' => 'Meal type: breakfast, lunch, or dinner' },
            'name' => { 'type' => 'string', 'description' => 'Restaurant name' },
            'cuisine' => { 'type' => 'string', 'description' => 'Type of cuisine' },
            'estimated_cost_per_person_usd' => { 'type' => 'number', 'description' => 'Cost per person' },
            'rating' => { 'type' => 'number', 'description' => 'Rating from 0.0 to 5.0' },
            'google_maps_url' => { 'type' => [ 'string', 'null' ], 'description' => 'Google Maps URL for the restaurant location (optional, can be null)' }
          },
          'required' => [ 'meal', 'name', 'cuisine', 'estimated_cost_per_person_usd', 'rating', 'google_maps_url' ],
          'additionalProperties' => false
        }
      }
    end
  end
end
