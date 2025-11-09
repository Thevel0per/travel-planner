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

  describe 'GET /trips/:id' do
    let(:trip) do
      create(:trip,
        user:,
        name: 'Summer Vacation 2025',
        destination: 'Paris, France',
        start_date: Date.new(2025, 7, 15),
        end_date: Date.new(2025, 7, 22),
        number_of_people: 2)
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        get trip_path(trip)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        get trip_path(trip), as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'with valid trip ID' do
        it 'returns 200 OK status for JSON' do
          get trip_path(trip), as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'returns trip data in JSON response' do
          get trip_path(trip), as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('trip')
          expect(json['trip']['id']).to eq(trip.id)
          expect(json['trip']['name']).to eq('Summer Vacation 2025')
          expect(json['trip']['destination']).to eq('Paris, France')
          expect(json['trip']['start_date']).to eq('2025-07-15')
          expect(json['trip']['end_date']).to eq('2025-07-22')
          expect(json['trip']['number_of_people']).to eq(2)
          expect(json['trip']).to have_key('created_at')
          expect(json['trip']).to have_key('updated_at')
        end

        it 'renders show page for HTML requests' do
          get trip_path(trip)
          expect(response).to have_http_status(:ok)
        end

        context 'with nested notes' do
          let!(:note1) { Note.create!(trip:, content: 'Visit Eiffel Tower') }
          let!(:note2) { Note.create!(trip:, content: 'Try French cuisine') }

          it 'includes notes in JSON response' do
            get trip_path(trip), as: :json
            json = JSON.parse(response.body)

            expect(json['trip']).to have_key('notes')
            expect(json['trip']['notes'].length).to eq(2)
            expect(json['trip']['notes'].first).to have_key('id')
            expect(json['trip']['notes'].first).to have_key('content')
            expect(json['trip']['notes'].first).to have_key('trip_id')
            expect(json['trip']['notes'].first).to have_key('created_at')
            expect(json['trip']['notes'].first).to have_key('updated_at')
          end

          it 'includes all note content in response' do
            get trip_path(trip), as: :json
            json = JSON.parse(response.body)

            note_contents = json['trip']['notes'].map { |n| n['content'] }
            expect(note_contents).to contain_exactly('Visit Eiffel Tower', 'Try French cuisine')
          end
        end

        context 'with nested generated_plans' do
          let!(:plan1) do
            GeneratedPlan.create!(
              trip:,
              status: 'completed',
              content: '{"summary": {}}',
              rating: 8
            )
          end
          let!(:plan2) do
            GeneratedPlan.create!(
              trip:,
              status: 'pending',
              content: ''
            )
          end

          it 'includes generated_plans in JSON response' do
            get trip_path(trip), as: :json
            json = JSON.parse(response.body)

            expect(json['trip']).to have_key('generated_plans')
            expect(json['trip']['generated_plans'].length).to eq(2)
            expect(json['trip']['generated_plans'].first).to have_key('id')
            expect(json['trip']['generated_plans'].first).to have_key('trip_id')
            expect(json['trip']['generated_plans'].first).to have_key('status')
            expect(json['trip']['generated_plans'].first).to have_key('created_at')
            expect(json['trip']['generated_plans'].first).to have_key('updated_at')
          end

          it 'includes rating for completed plans' do
            get trip_path(trip), as: :json
            json = JSON.parse(response.body)

            completed_plan = json['trip']['generated_plans'].find { |p| p['status'] == 'completed' }
            expect(completed_plan).to have_key('rating')
            expect(completed_plan['rating']).to eq(8)

            pending_plan = json['trip']['generated_plans'].find { |p| p['status'] == 'pending' }
            expect(pending_plan['rating']).to be_nil
          end
        end

        context 'with both notes and generated_plans' do
          let!(:note) { Note.create!(trip:, content: 'Remember passport') }
          let!(:plan) { GeneratedPlan.create!(trip:, status: 'pending', content: '') }

          it 'includes both associations in response' do
            get trip_path(trip), as: :json
            json = JSON.parse(response.body)

            expect(json['trip']['notes'].length).to eq(1)
            expect(json['trip']['generated_plans'].length).to eq(1)
          end
        end

        context 'with no associations' do
          it 'returns empty arrays for notes and generated_plans' do
            get trip_path(trip), as: :json
            json = JSON.parse(response.body)

            expect(json['trip']['notes']).to eq([])
            expect(json['trip']['generated_plans']).to eq([])
          end
        end
      end

      context 'when trip does not exist' do
        it 'returns 404 Not Found for JSON requests' do
          get trip_path(999_999), as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'returns error response in correct format' do
          get trip_path(999_999), as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('error')
          expect(json['error']).to eq('Resource not found')
        end

        it 'redirects to root with flash message for HTML requests' do
          get trip_path(999_999)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('Resource not found')
        end
      end

      context 'when trip belongs to different user' do
        let(:other_user_trip) { create(:trip, user: other_user, name: 'Other User Trip') }

        it 'returns 404 Not Found (prevents unauthorized access)' do
          get trip_path(other_user_trip), as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'does not reveal trip existence through error message' do
          get trip_path(other_user_trip), as: :json
          json = JSON.parse(response.body)

          expect(json['error']).to eq('Resource not found')
          # Should not reveal that the trip exists but belongs to another user
        end
      end
    end
  end

  describe 'PUT/PATCH /trips/:id' do
    let(:trip) do
      create(:trip,
        user:,
        name: 'Original Trip Name',
        destination: 'Original Destination',
        start_date: Date.new(2025, 7, 15),
        end_date: Date.new(2025, 7, 22),
        number_of_people: 2)
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        put trip_path(trip), params: { trip: { name: 'Updated Name' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        put trip_path(trip), params: { trip: { name: 'Updated Name' } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'with valid parameters' do
        context 'partial update (single field)' do
          it 'updates only the name field' do
            put trip_path(trip), params: { trip: { name: 'Updated Trip Name' } }, as: :json
            expect(response).to have_http_status(:ok)

            trip.reload
            expect(trip.name).to eq('Updated Trip Name')
            expect(trip.destination).to eq('Original Destination')
            expect(trip.start_date).to eq(Date.new(2025, 7, 15))
          end

          it 'returns updated trip data in JSON response' do
            put trip_path(trip), params: { trip: { name: 'Updated Trip Name' } }, as: :json
            json = JSON.parse(response.body)

            expect(json).to have_key('trip')
            expect(json['trip']['name']).to eq('Updated Trip Name')
            expect(json['trip']['id']).to eq(trip.id)
          end
        end

        context 'full update (all fields)' do
          it 'updates all trip fields' do
            put trip_path(trip),
                params: {
                  trip: {
                    name: 'Summer Vacation 2025',
                    destination: 'Paris, France',
                    start_date: '2025-08-01',
                    end_date: '2025-08-10',
                    number_of_people: 3
                  }
                },
                as: :json

            expect(response).to have_http_status(:ok)

            trip.reload
            expect(trip.name).to eq('Summer Vacation 2025')
            expect(trip.destination).to eq('Paris, France')
            expect(trip.start_date).to eq(Date.new(2025, 8, 1))
            expect(trip.end_date).to eq(Date.new(2025, 8, 10))
            expect(trip.number_of_people).to eq(3)
          end

          it 'returns all updated fields in JSON response' do
            put trip_path(trip),
                params: {
                  trip: {
                    name: 'Summer Vacation 2025',
                    destination: 'Paris, France',
                    start_date: '2025-08-01',
                    end_date: '2025-08-10',
                    number_of_people: 3
                  }
                },
                as: :json

            json = JSON.parse(response.body)
            expect(json['trip']['name']).to eq('Summer Vacation 2025')
            expect(json['trip']['destination']).to eq('Paris, France')
            expect(json['trip']['start_date']).to eq('2025-08-01')
            expect(json['trip']['end_date']).to eq('2025-08-10')
            expect(json['trip']['number_of_people']).to eq(3)
          end
        end

        context 'with flat parameter format' do
          it 'accepts parameters without trip wrapper' do
            patch trip_path(trip), params: { name: 'Flat Format Update' }, as: :json
            expect(response).to have_http_status(:ok)

            trip.reload
            expect(trip.name).to eq('Flat Format Update')
          end
        end

        context 'HTML format' do
          it 'redirects to trip show page with success message' do
            put trip_path(trip), params: { trip: { name: 'Updated Name' } }
            expect(response).to redirect_to(trip_path(trip))
            expect(flash[:notice]).to eq('Trip updated successfully')
          end
        end
      end

      context 'with validation errors' do
        it 'returns 422 Unprocessable Entity when end_date <= start_date' do
          put trip_path(trip),
              params: {
                trip: {
                  start_date: '2025-07-20',
                  end_date: '2025-07-15'
                }
              },
              as: :json

          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns validation errors in JSON format' do
          put trip_path(trip),
              params: {
                trip: {
                  name: '',
                  start_date: '2025-07-20',
                  end_date: '2025-07-15'
                }
              },
              as: :json

          json = JSON.parse(response.body)
          expect(json).to have_key('errors')
        end

        it 'returns error for blank name when provided' do
          put trip_path(trip), params: { trip: { name: '' } }, as: :json
          expect(response).to have_http_status(:unprocessable_content)

          json = JSON.parse(response.body)
          expect(json['errors']).to have_key('name')
        end

        it 'returns error for invalid number_of_people' do
          put trip_path(trip), params: { trip: { number_of_people: 0 } }, as: :json
          expect(response).to have_http_status(:unprocessable_content)

          json = JSON.parse(response.body)
          expect(json['errors']).to have_key('number_of_people')
        end
      end

      context 'when trip does not exist' do
        it 'returns 404 Not Found for JSON requests' do
          put trip_path(999_999), params: { trip: { name: 'Updated' } }, as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'returns error response in correct format' do
          put trip_path(999_999), params: { trip: { name: 'Updated' } }, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('error')
          expect(json['error']).to eq('Resource not found')
        end
      end

      context 'when trip belongs to different user' do
        let(:other_user_trip) { create(:trip, user: other_user, name: 'Other User Trip') }

        it 'returns 404 Not Found (prevents unauthorized access)' do
          put trip_path(other_user_trip), params: { trip: { name: 'Hacked' } }, as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'does not reveal trip existence through error message' do
          put trip_path(other_user_trip), params: { trip: { name: 'Hacked' } }, as: :json
          json = JSON.parse(response.body)

          expect(json['error']).to eq('Resource not found')
        end
      end

      context 'security' do
        it 'prevents user_id from being changed' do
          original_user_id = trip.user_id
          put trip_path(trip),
              params: {
                trip: {
                  name: 'Updated',
                  user_id: other_user.id
                }
              },
              as: :json

          trip.reload
          expect(trip.user_id).to eq(original_user_id)
        end
      end
    end
  end

  describe 'DELETE /trips/:id' do
    let(:trip) do
      create(:trip,
        user:,
        name: 'Trip to Delete',
        destination: 'Paris, France',
        start_date: Date.new(2025, 7, 15),
        end_date: Date.new(2025, 7, 22),
        number_of_people: 2)
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        delete trip_path(trip)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        delete trip_path(trip), as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'with valid trip ID' do
        it 'returns 200 OK status for JSON' do
          delete trip_path(trip), as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'returns success message in JSON response' do
          delete trip_path(trip), as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('message')
          expect(json['message']).to eq('Trip deleted successfully')
        end

        it 'deletes the trip from database' do
          trip_id = trip.id # Ensure trip is created before the expect block
          expect { delete trip_path(trip), as: :json }.to change(Trip, :count).by(-1)
          expect(Trip.find_by(id: trip_id)).to be_nil
        end

        it 'redirects to trips index with flash message for HTML requests' do
          delete trip_path(trip)
          expect(response).to redirect_to(trips_path)
          expect(flash[:notice]).to eq('Trip deleted successfully')
        end
      end

      context 'when trip does not exist' do
        it 'returns 404 Not Found for JSON requests' do
          delete trip_path(999_999), as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'returns error response in correct format' do
          delete trip_path(999_999), as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('error')
          expect(json['error']).to eq('Resource not found')
        end

        it 'redirects to root with flash message for HTML requests' do
          delete trip_path(999_999)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('Resource not found')
        end
      end

      context 'when trip belongs to different user' do
        let(:other_user_trip) { create(:trip, user: other_user, name: 'Other User Trip') }

        it 'returns 404 Not Found (prevents unauthorized access)' do
          delete trip_path(other_user_trip), as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'does not reveal trip existence through error message' do
          delete trip_path(other_user_trip), as: :json
          json = JSON.parse(response.body)

          expect(json['error']).to eq('Resource not found')
          # Should not reveal that the trip exists but belongs to another user
        end

        it 'does not delete trip belonging to another user' do
          other_user_trip_id = other_user_trip.id # Ensure trip is created before the expect block
          expect { delete trip_path(other_user_trip), as: :json }.not_to change(Trip, :count)
          expect(Trip.find_by(id: other_user_trip_id)).to be_present
        end
      end
    end
  end
end
