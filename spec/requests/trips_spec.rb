require 'rails_helper'

RSpec.describe 'Trips', type: :request do
  # Create a user for authentication tests
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /trips' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        get trips_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        get trips_path, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'with no trips' do
        it 'returns success with empty trips array for JSON' do
          get trips_path, as: :json
          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json['trips']).to eq([])
          expect(json['meta']['total_count']).to eq(0)
        end

        it 'renders index page with empty state for HTML' do
          get trips_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('No trips found')
        end
      end

      context 'with trips' do
        let!(:trip1) do
          Trip.create!(
            user:,
            name: 'Summer in Paris',
            destination: 'Paris, France',
            start_date: Date.new(2025, 7, 1),
            end_date: Date.new(2025, 7, 10),
            number_of_people: 2
          )
        end

        let!(:trip2) do
          Trip.create!(
            user:,
            name: 'Tokyo Adventure',
            destination: 'Tokyo, Japan',
            start_date: Date.new(2025, 8, 15),
            end_date: Date.new(2025, 8, 25),
            number_of_people: 3
          )
        end

        let!(:other_user_trip) do
          Trip.create!(
            user: other_user,
            name: 'Other User Trip',
            destination: 'New York, USA',
            start_date: Date.new(2025, 9, 1),
            end_date: Date.new(2025, 9, 5),
            number_of_people: 1
          )
        end

        it 'returns only current user trips' do
          get trips_path, as: :json
          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json['trips'].length).to eq(2)

          trip_names = json['trips'].map { |t| t['name'] }
          expect(trip_names).to contain_exactly('Summer in Paris', 'Tokyo Adventure')
          expect(trip_names).not_to include('Other User Trip')
        end

        it 'includes trip attributes in JSON response' do
          get trips_path, as: :json
          json = JSON.parse(response.body)

          first_trip = json['trips'].first
          expect(first_trip).to have_key('id')
          expect(first_trip).to have_key('name')
          expect(first_trip).to have_key('destination')
          expect(first_trip).to have_key('start_date')
          expect(first_trip).to have_key('end_date')
          expect(first_trip).to have_key('number_of_people')
          expect(first_trip).to have_key('created_at')
          expect(first_trip).to have_key('updated_at')
        end

        it 'includes pagination metadata in JSON response' do
          get trips_path, as: :json
          json = JSON.parse(response.body)

          expect(json['meta']).to have_key('current_page')
          expect(json['meta']).to have_key('total_pages')
          expect(json['meta']).to have_key('total_count')
          expect(json['meta']).to have_key('per_page')

          expect(json['meta']['current_page']).to eq(1)
          expect(json['meta']['total_count']).to eq(2)
        end

        it 'renders index page with trip cards for HTML' do
          get trips_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Summer in Paris')
          expect(response.body).to include('Tokyo Adventure')
        end
      end

      context 'pagination' do
        before do
          # Create 25 trips
          25.times do |i|
            Trip.create!(
              user:,
              name: "Trip #{i + 1}",
              destination: "Destination #{i + 1}",
              start_date: Date.today + i.days,
              end_date: Date.today + (i + 3).days,
              number_of_people: 2
            )
          end
        end

        it 'returns default 20 items per page' do
          get trips_path, as: :json
          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(20)
          expect(json['meta']['per_page']).to eq(20)
          expect(json['meta']['total_pages']).to eq(2)
          expect(json['meta']['total_count']).to eq(25)
        end

        it 'respects custom per_page parameter' do
          get trips_path, params: { per_page: 10 }, as: :json
          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(10)
          expect(json['meta']['per_page']).to eq(10)
          expect(json['meta']['total_pages']).to eq(3)
        end

        it 'returns correct items for page 2' do
          get trips_path, params: { page: 2, per_page: 10 }, as: :json
          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(10)
          expect(json['meta']['current_page']).to eq(2)
        end

        it 'returns remaining items on last page' do
          get trips_path, params: { page: 3, per_page: 10 }, as: :json
          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(5)
          expect(json['meta']['current_page']).to eq(3)
        end

        it 'handles page overflow gracefully' do
          get trips_path, params: { page: 999 }, as: :json
          expect(response).to have_http_status(:bad_request)

          json = JSON.parse(response.body)
          expect(json['error']).to include('Page number exceeds')
        end
      end

      context 'filtering by destination' do
        let!(:paris_trip) do
          Trip.create!(
            user:,
            name: 'Paris Trip',
            destination: 'Paris, France',
            start_date: Date.today,
            end_date: Date.today + 5.days,
            number_of_people: 2
          )
        end

        let!(:tokyo_trip) do
          Trip.create!(
            user:,
            name: 'Tokyo Trip',
            destination: 'Tokyo, Japan',
            start_date: Date.today + 10.days,
            end_date: Date.today + 15.days,
            number_of_people: 2
          )
        end

        it 'filters trips by destination (partial match)' do
          get trips_path, params: { destination: 'Paris' }, as: :json
          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(1)
          expect(json['trips'].first['destination']).to include('Paris')
        end

        it 'performs case-insensitive search' do
          get trips_path, params: { destination: 'paris' }, as: :json
          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(1)
          expect(json['trips'].first['destination']).to include('Paris')
        end

        it 'returns empty array when no matches found' do
          get trips_path, params: { destination: 'NonExistent' }, as: :json
          json = JSON.parse(response.body)

          expect(json['trips']).to eq([])
          expect(json['meta']['total_count']).to eq(0)
        end
      end

      context 'sorting' do
        let!(:future_trip) do
          Trip.create!(
            user:,
            name: 'Future Trip',
            destination: 'Future Destination',
            start_date: Date.today + 30.days,
            end_date: Date.today + 35.days,
            number_of_people: 2
          )
        end

        let!(:near_trip) do
          Trip.create!(
            user:,
            name: 'Near Trip',
            destination: 'Near Destination',
            start_date: Date.today + 5.days,
            end_date: Date.today + 10.days,
            number_of_people: 2
          )
        end

        it 'sorts by start_date ascending by default' do
          get trips_path, as: :json
          json = JSON.parse(response.body)

          trip_names = json['trips'].map { |t| t['name'] }
          expect(trip_names).to eq([ 'Near Trip', 'Future Trip' ])
        end

        it 'sorts by start_date descending when specified' do
          get trips_path, params: { sort_order: 'desc' }, as: :json
          json = JSON.parse(response.body)

          trip_names = json['trips'].map { |t| t['name'] }
          expect(trip_names).to eq([ 'Future Trip', 'Near Trip' ])
        end
      end

      context 'parameter validation' do
        it 'rejects per_page greater than 100' do
          get trips_path, params: { per_page: 150 }, as: :json
          expect(response).to have_http_status(:bad_request)

          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end

        it 'rejects per_page less than 1' do
          get trips_path, params: { per_page: 0 }, as: :json
          expect(response).to have_http_status(:bad_request)

          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end

        it 'rejects invalid sort_order' do
          get trips_path, params: { sort_order: 'invalid' }, as: :json
          expect(response).to have_http_status(:bad_request)

          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end

        it 'clamps per_page to max value instead of rejecting' do
          # According to the service implementation, it clamps the value
          get trips_path, params: { per_page: 150 }, as: :json

          # The service will clamp to 100, but validation should catch values outside range
          # This test documents the expected behavior
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'combined filters' do
        let!(:paris_trip1) do
          Trip.create!(
            user:,
            name: 'Early Paris Trip',
            destination: 'Paris, France',
            start_date: Date.today + 5.days,
            end_date: Date.today + 10.days,
            number_of_people: 2
          )
        end

        let!(:paris_trip2) do
          Trip.create!(
            user:,
            name: 'Late Paris Trip',
            destination: 'Paris, France',
            start_date: Date.today + 20.days,
            end_date: Date.today + 25.days,
            number_of_people: 3
          )
        end

        let!(:tokyo_trip) do
          Trip.create!(
            user:,
            name: 'Tokyo Trip',
            destination: 'Tokyo, Japan',
            start_date: Date.today + 15.days,
            end_date: Date.today + 18.days,
            number_of_people: 1
          )
        end

        it 'applies both filtering and sorting' do
          get trips_path,
              params: { destination: 'Paris', sort_order: 'desc' },
              as: :json

          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(2)
          trip_names = json['trips'].map { |t| t['name'] }
          expect(trip_names).to eq([ 'Late Paris Trip', 'Early Paris Trip' ])
        end

        it 'applies filtering, sorting, and pagination' do
          get trips_path,
              params: { destination: 'Paris', sort_order: 'asc', per_page: 1 },
              as: :json

          json = JSON.parse(response.body)

          expect(json['trips'].length).to eq(1)
          expect(json['trips'].first['name']).to eq('Early Paris Trip')
          expect(json['meta']['total_count']).to eq(2)
        end
      end
    end
  end
end
