# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe GeneratedPlans::Generate do
  let(:user) { create(:user) }

  let!(:trip) do
    Trip.create!(
      user:,
      name: 'Summer Vacation',
      destination: 'Paris, France',
      start_date: Date.new(2025, 7, 1),
      end_date: Date.new(2025, 7, 5),
      number_of_people: 2
    )
  end

  let!(:user_preferences) do
    UserPreference.create!(
      user:,
      budget: 'standard',
      accommodation: 'hotel',
      activities: 'sightseeing,cultural',
      eating_habits: 'restaurants_only'
    )
  end

  let(:service) do
    described_class.new(
      trip_id: trip.id,
      user_id: user.id
    )
  end

  let(:valid_plan_json) do
    {
      summary: {
        total_cost_usd: 2000.0,
        cost_per_person_usd: 1000.0,
        duration_days: 5,
        number_of_people: 2
      },
      daily_itinerary: [
        {
          day: 1,
          date: '2025-07-01',
          activities: [
            {
              time: '10:00 AM',
              name: 'Eiffel Tower Visit',
              duration_minutes: 180,
              estimated_cost_usd: 60.0,
              estimated_cost_per_person_usd: 30.0,
              rating: 4.8,
              description: 'Visit the iconic Eiffel Tower'
            }
          ],
          restaurants: [
            {
              meal: 'lunch',
              name: 'Le Petit Cler',
              cuisine: 'French',
              estimated_cost_per_person_usd: 25.0,
              rating: 4.5
            }
          ]
        },
        {
          day: 2,
          date: '2025-07-02',
          activities: [
            {
              time: '09:00 AM',
              name: 'Louvre Museum',
              duration_minutes: 240,
              estimated_cost_usd: 50.0,
              estimated_cost_per_person_usd: 25.0,
              rating: 4.9,
              description: 'Explore the Louvre'
            }
          ],
          restaurants: [
            {
              meal: 'dinner',
              name: 'Bistro Parisien',
              cuisine: 'French',
              estimated_cost_per_person_usd: 35.0,
              rating: 4.3
            }
          ]
        },
        {
          day: 3,
          date: '2025-07-03',
          activities: [
            {
              time: '11:00 AM',
              name: 'Notre-Dame',
              duration_minutes: 120,
              estimated_cost_usd: 0.0,
              estimated_cost_per_person_usd: 0.0,
              rating: 4.7,
              description: 'Visit Notre-Dame'
            }
          ],
          restaurants: [
            {
              meal: 'lunch',
              name: 'Café de Flore',
              cuisine: 'French',
              estimated_cost_per_person_usd: 30.0,
              rating: 4.4
            }
          ]
        },
        {
          day: 4,
          date: '2025-07-04',
          activities: [
            {
              time: '10:30 AM',
              name: 'Arc de Triomphe',
              duration_minutes: 90,
              estimated_cost_usd: 26.0,
              estimated_cost_per_person_usd: 13.0,
              rating: 4.6,
              description: 'Arc de Triomphe'
            }
          ],
          restaurants: [
            {
              meal: 'dinner',
              name: 'Le Comptoir',
              cuisine: 'French',
              estimated_cost_per_person_usd: 40.0,
              rating: 4.6
            }
          ]
        },
        {
          day: 5,
          date: '2025-07-05',
          activities: [
            {
              time: '10:00 AM',
              name: 'Montmartre',
              duration_minutes: 150,
              estimated_cost_usd: 0.0,
              estimated_cost_per_person_usd: 0.0,
              rating: 4.5,
              description: 'Explore Montmartre'
            }
          ],
          restaurants: [
            {
              meal: 'lunch',
              name: 'La Maison Rose',
              cuisine: 'French',
              estimated_cost_per_person_usd: 28.0,
              rating: 4.4
            }
          ]
        }
      ]
    }.to_json
  end

  describe '#initialize' do
    it 'sets trip_id and user_id' do
      expect(service.trip_id).to eq(trip.id)
      expect(service.user_id).to eq(user.id)
    end
  end

  describe '#call' do
    context 'when trip not found' do
      let(:service) do
        described_class.new(
          trip_id: 99999,
          user_id: user.id
        )
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
      end
    end

    context 'when user does not own the trip' do
      let(:other_user) { create(:user) }
      let(:service) do
        described_class.new(
          trip_id: trip.id,
          user_id: other_user.id
        )
      end

      before do
        UserPreference.create!(user: other_user, budget: 'standard')
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
      end
    end

    context 'with successful API response' do
      before do
        stub_openrouter_success(content: valid_plan_json)
      end

      it 'returns success result' do
        result = service.call
        expect(result).to be_success
      end

      it 'includes plan content' do
        result = service.call
        expect(result.data).to be_a(Schemas::GeneratedPlanContent)
      end

      it 'has correct summary data' do
        result = service.call
        summary = result.data&.summary

        expect(summary&.duration_days).to eq(5)
        expect(summary&.number_of_people).to eq(2)
      end
    end

    context 'with API authentication error' do
      before do
        stub_openrouter_error(status: 401, message: 'Invalid API key')
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
      end

      it 'is not retryable' do
        result = service.call
        expect(result).not_to be_retryable
      end
    end

    context 'with rate limit error' do
      before do
        stub_openrouter_rate_limit
      end

      it 'is retryable' do
        result = service.call
        expect(result).to be_retryable
      end
    end

    context 'with malformed API response' do
      before do
        stub_openrouter_success(content: 'not valid json')
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
      end

      it 'is retryable' do
        result = service.call
        expect(result).to be_retryable
      end
    end

    context 'with plan validation errors' do
      let(:invalid_plan_json) do
        data = JSON.parse(valid_plan_json)
        data['summary']['duration_days'] = 3
        data.to_json
      end

      before do
        stub_openrouter_success(content: invalid_plan_json)
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
      end

      it 'includes validation error message' do
        result = service.call
        expect(result.error_message).to include('Invalid plan')
      end

      it 'is retryable' do
        result = service.call
        expect(result).to be_retryable
      end
    end
  end
end
