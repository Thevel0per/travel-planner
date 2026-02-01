# frozen_string_literal: true

FactoryBot.define do
  factory :generated_plan do
    association :trip
    status { 'pending' }
    content { '{}' }
    rating { nil }

    trait :pending do
      status { 'pending' }
    end

    trait :generating do
      status { 'generating' }
    end

    trait :completed do
      status { 'completed' }
      content do
        {
          summary: {
            total_cost_usd: 1500.00,
            cost_per_person_usd: 750.00,
            duration_days: 7,
            number_of_people: 2
          },
          hotels: [
            {
              name: 'Sample Hotel',
              address: '123 Main St',
              price_per_night_usd: 150.00,
              rating: 4.5,
              amenities: [ 'WiFi', 'Pool' ]
            }
          ],
          daily_itinerary: [
            {
              day: 1,
              date: '2026-01-01',
              activities: [
                {
                  time: '09:00',
                  name: 'Morning Activity',
                  description: 'Sample activity description',
                  duration_minutes: 120,
                  cost_per_person_usd: 25.00
                }
              ],
              restaurants: [
                {
                  meal_type: 'lunch',
                  name: 'Sample Restaurant',
                  cuisine: 'Italian',
                  average_cost_per_person_usd: 30.00
                }
              ]
            }
          ]
        }.to_json
      end
    end

    trait :failed do
      status { 'failed' }
    end

    trait :with_rating do
      status { 'completed' }
      rating { 8 }
      content do
        {
          summary: {
            total_cost_usd: 1000.00,
            cost_per_person_usd: 500.00,
            duration_days: 5,
            number_of_people: 2
          },
          hotels: [],
          daily_itinerary: []
        }.to_json
      end
    end
  end
end
