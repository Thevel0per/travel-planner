# typed: strict
# frozen_string_literal: true

module TravelPlanGeneration
  # Builds prompts for AI travel plan generation
  class PromptBuilder
    extend T::Sig

    sig { returns(Trip) }
    attr_reader :trip

    sig { returns(UserPreference) }
    attr_reader :user_preferences

    sig { returns(T::Array[Note]) }
    attr_reader :notes

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
    end

    # Build the messages array for the API
    sig { returns(T::Array[T::Hash[String, String]]) }
    def build_messages
      [
        { 'role' => 'system', 'content' => system_message },
        { 'role' => 'user', 'content' => user_message }
      ]
    end

    private

    # System message defining the AI's role and output format
    sig { returns(String) }
    def system_message
      <<~SYSTEM
        You are an expert travel planning assistant. Your task is to create detailed, realistic, and exciting travel itineraries based on user preferences.

        REQUIREMENTS:
        1. Generate a complete day-by-day itinerary with specific activities and restaurant recommendations
        2. Provide realistic cost estimates in USD based on the destination and budget level
        3. Include activity ratings (0.0-5.0) based on popular review sites
        4. Ensure all activities fit realistically within each day's timeframe
        5. Consider the user's preferences for budget, accommodation type, activities, and eating habits
        6. Include specific times for each activity (e.g., "10:00 AM")
        7. Provide engaging descriptions for each activity
        8. Recommend restaurants for breakfast, lunch, and dinner each day

        OUTPUT FORMAT:
        You must respond with valid JSON matching the exact schema provided. All costs should be in USD.
        Ratings should be realistic (3.5-5.0 for popular attractions, 2.0-4.5 for restaurants).
      SYSTEM
    end

    # User message with trip details and preferences
    sig { returns(String) }
    def user_message
      duration = calculate_duration

      message = <<~USER
        Please create a detailed travel itinerary for the following trip:

        TRIP DETAILS:
        - Destination: #{trip.destination}
        - Start Date: #{trip.start_date.strftime('%B %d, %Y')}
        - End Date: #{trip.end_date.strftime('%B %d, %Y')}
        - Duration: #{duration} days
        - Number of People: #{trip.number_of_people}

        USER PREFERENCES:
      USER

      message += format_preferences
      message += format_notes if notes.any?
      message += "\nPlease generate a complete itinerary with daily activities and restaurant recommendations."
      message
    end

    sig { returns(String) }
    def format_preferences
      preferences = []
      preferences << "- Budget: #{format_budget(user_preferences.budget)}" if user_preferences.budget.present?
      preferences << "- Accommodation: #{format_accommodation(user_preferences.accommodation)}" if user_preferences.accommodation.present?
      preferences << "- Eating Habits: #{format_eating_habits(user_preferences.eating_habits)}" if user_preferences.eating_habits.present?

      if user_preferences.activities.present?
        activities = user_preferences.activities.split(',').map(&:strip)
        preferences << "- Preferred Activities: #{activities.map { |a| format_activity(a) }.join(', ')}"
      end

      preferences.join("\n") + "\n"
    end

    sig { returns(String) }
    def format_notes
      notes_text = "\nADDITIONAL NOTES FROM USER:\n"
      notes.each do |note|
        notes_text += "- #{note.content}\n"
      end
      notes_text
    end

    sig { returns(Integer) }
    def calculate_duration
      ((trip.end_date - trip.start_date).to_i + 1)
    end

    # Format enum values for display
    sig { params(budget: T.nilable(String)).returns(String) }
    def format_budget(budget)
      case budget
      when 'budget_conscious' then 'Budget-conscious (affordable options)'
      when 'standard' then 'Standard (mid-range options)'
      when 'luxury' then 'Luxury (premium options)'
      else 'Standard'
      end
    end

    sig { params(accommodation: T.nilable(String)).returns(String) }
    def format_accommodation(accommodation)
      case accommodation
      when 'hotel' then 'Hotels'
      when 'airbnb' then 'Airbnb/Vacation Rentals'
      when 'hostel' then 'Hostels'
      when 'resort' then 'Resorts'
      when 'camping' then 'Camping'
      else accommodation.to_s.capitalize
      end
    end

    sig { params(eating_habits: T.nilable(String)).returns(String) }
    def format_eating_habits(eating_habits)
      case eating_habits
      when 'restaurants_only' then 'Restaurants only (all meals at restaurants)'
      when 'self_prepared' then 'Self-prepared (groceries and cooking)'
      when 'mix' then 'Mix (combination of restaurants and self-prepared)'
      else 'Mix'
      end
    end

    sig { params(activity: String).returns(String) }
    def format_activity(activity)
      activity.split('_').map(&:capitalize).join(' ')
    end
  end
end

