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
          expect(response.body).to include('No trips yet!')
        end
      end

      context 'with trips' do
        let!(:trip1) do
          create(:trip,
            user:,
            name: 'Summer in Paris',
            destination: 'Paris, France',
            start_date: Date.new(2025, 7, 1),
            end_date: Date.new(2025, 7, 10),
            number_of_people: 2)
        end

        let!(:trip2) do
          create(:trip,
            user:,
            name: 'Tokyo Adventure',
            destination: 'Tokyo, Japan',
            start_date: Date.new(2025, 8, 15),
            end_date: Date.new(2025, 8, 25),
            number_of_people: 3)
        end

        let!(:other_user_trip) { create(:trip, user: other_user, name: 'Other User Trip', destination: 'New York, USA') }

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
          expect(response.body).to include('Paris, France')
          expect(response.body).to include('Tokyo, Japan')
        end
      end

      context 'pagination' do
        before do
          # Create 25 trips
          create_list(:trip, 25, user:)
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
        let!(:paris_trip) { create(:trip, user:, name: 'Paris Trip', destination: 'Paris, France') }
        let!(:tokyo_trip) { create(:trip, user:, name: 'Tokyo Trip', destination: 'Tokyo, Japan') }

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
        let!(:future_trip) { create(:trip, user:, name: 'Future Trip', start_date: Date.today + 30.days, end_date: Date.today + 35.days) }
        let!(:near_trip) { create(:trip, user:, name: 'Near Trip', start_date: Date.today + 5.days, end_date: Date.today + 10.days) }

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
        let!(:paris_trip1) { create(:trip, user:, name: 'Early Paris Trip', destination: 'Paris, France', start_date: Date.today + 5.days, end_date: Date.today + 10.days) }
        let!(:paris_trip2) { create(:trip, user:, name: 'Late Paris Trip', destination: 'Paris, France', start_date: Date.today + 20.days, end_date: Date.today + 25.days, number_of_people: 3) }
        let!(:tokyo_trip) { create(:trip, user:, name: 'Tokyo Trip', destination: 'Tokyo, Japan', start_date: Date.today + 15.days, end_date: Date.today + 18.days, number_of_people: 1) }

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

  describe 'POST /trips' do
    let(:valid_trip_params) do
      {
        trip: {
          name: 'Summer Vacation 2025',
          destination: 'Paris, France',
          start_date: '2025-07-15',
          end_date: '2025-07-22',
          number_of_people: 2
        }
      }
    end
    let(:mock_service) { instance_double(Trips::Create) }

    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        post trips_path, params: valid_trip_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        post trips_path, params: valid_trip_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'with valid parameters' do
        let(:trip) { create(:trip, user:, name: 'Summer Vacation 2025', destination: 'Paris, France', start_date: Date.new(2025, 7, 15), end_date: Date.new(2025, 7, 22), number_of_people: 2) }

        before do
          allow(Trips::Create).to receive(:new).and_return(mock_service)
          allow(mock_service).to receive(:call).and_return(trip)
        end

        it 'calls Trips::Create service with correct arguments' do
          expect(Trips::Create).to receive(:new).with(user:, command: instance_of(Commands::TripCreateCommand)).and_return(mock_service)
          expect(mock_service).to receive(:call).and_return(trip)

          post trips_path, params: valid_trip_params, as: :json
        end

        it 'returns 201 Created status' do
          post trips_path, params: valid_trip_params, as: :json
          expect(response).to have_http_status(:created)
        end

        it 'returns trip data in JSON response' do
          post trips_path, params: valid_trip_params, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('trip')
          expect(json['trip']).to have_key('id')
          expect(json['trip']['name']).to eq('Summer Vacation 2025')
          expect(json['trip']['destination']).to eq('Paris, France')
          expect(json['trip']['start_date']).to eq('2025-07-15')
          expect(json['trip']['end_date']).to eq('2025-07-22')
          expect(json['trip']['number_of_people']).to eq(2)
        end

        it 'accepts flat parameter format (without trip key)' do
          flat_params = {
            name: 'Flat Format Trip',
            destination: 'Tokyo, Japan',
            start_date: '2025-08-01',
            end_date: '2025-08-10',
            number_of_people: 3
          }

          flat_trip = create(:trip, user:, name: 'Flat Format Trip', destination: 'Tokyo, Japan', start_date: Date.new(2025, 8, 1), end_date: Date.new(2025, 8, 10), number_of_people: 3)
          allow(mock_service).to receive(:call).and_return(flat_trip)

          post trips_path, params: flat_params, as: :json
          expect(response).to have_http_status(:created)

          json = JSON.parse(response.body)
          expect(json['trip']['name']).to eq('Flat Format Trip')
        end
      end

      context 'with validation errors' do
        let(:invalid_trip) do
          build(:trip, user:, name: '', destination: '').tap do |t|
            t.valid? # Trigger validations
          end
        end

        before do
          allow(Trips::Create).to receive(:new).and_return(mock_service)
          allow(mock_service).to receive(:call).and_return(invalid_trip)
        end

        it 'returns 422 Unprocessable Entity for validation errors' do
          post trips_path, params: valid_trip_params.deep_merge(trip: { name: '' }), as: :json
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns validation errors in JSON format' do
          post trips_path, params: valid_trip_params.deep_merge(trip: { name: '', destination: '' }), as: :json

          json = JSON.parse(response.body)
          expect(json).to have_key('errors')
          expect(json['errors']).to have_key('name')
          expect(json['errors']).to have_key('destination')
        end
      end
    end
  end
end
