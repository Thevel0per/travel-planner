require 'rails_helper'

RSpec.describe 'Preferences', type: :request do
  # Create a user for authentication tests
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /preferences' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        get preferences_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        get preferences_path, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'when user has preferences' do
        let!(:preferences) do
          create(:user_preference,
            user:,
            budget: 'standard',
            accommodation: 'hotel',
            activities: 'cultural,sightseeing',
            eating_habits: 'mix')
        end

        it 'returns 200 OK status for JSON' do
          get preferences_path, as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'returns preferences data in JSON response' do
          get preferences_path, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('preferences')
          expect(json['preferences']['id']).to eq(preferences.id)
          expect(json['preferences']['user_id']).to eq(user.id)
          expect(json['preferences']['budget']).to eq('standard')
          expect(json['preferences']['accommodation']).to eq('hotel')
          expect(json['preferences']['activities']).to eq('cultural,sightseeing')
          expect(json['preferences']['eating_habits']).to eq('mix')
        end

        it 'includes all required fields in JSON response' do
          get preferences_path, as: :json
          json = JSON.parse(response.body)

          pref = json['preferences']
          expect(pref).to have_key('id')
          expect(pref).to have_key('user_id')
          expect(pref).to have_key('budget')
          expect(pref).to have_key('accommodation')
          expect(pref).to have_key('activities')
          expect(pref).to have_key('eating_habits')
          expect(pref).to have_key('created_at')
          expect(pref).to have_key('updated_at')
        end

        it 'includes ISO 8601 formatted timestamps' do
          get preferences_path, as: :json
          json = JSON.parse(response.body)

          pref = json['preferences']
          expect(pref['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
          expect(pref['updated_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        end

        it 'handles nil values for optional fields' do
          preferences.update(budget: nil, accommodation: nil, eating_habits: nil, activities: nil)

          get preferences_path, as: :json
          json = JSON.parse(response.body)

          pref = json['preferences']
          expect(pref['budget']).to be_nil
          expect(pref['accommodation']).to be_nil
          expect(pref['eating_habits']).to be_nil
          expect(pref['activities']).to be_nil
        end

        it 'returns only current user preferences (not other users)' do
          other_preferences = create(:user_preference, user: other_user, budget: 'luxury')

          get preferences_path, as: :json
          json = JSON.parse(response.body)

          expect(json['preferences']['id']).to eq(preferences.id)
          expect(json['preferences']['id']).not_to eq(other_preferences.id)
          expect(json['preferences']['budget']).to eq('standard')
        end

        it 'redirects to root for HTML requests' do
          get preferences_path
          expect(response).to redirect_to(root_path)
        end
      end

      context 'when user has no preferences' do
        it 'returns 404 Not Found for JSON requests' do
          get preferences_path, as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'returns custom error message in JSON response' do
          get preferences_path, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('error')
          expect(json['error']).to eq('Preferences not found. Please create your preferences.')
        end

        it 'redirects to root with flash message for HTML requests' do
          get preferences_path
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('Preferences not found. Please create your preferences.')
        end
      end

      context 'with different preference values' do
        it 'handles budget_conscious budget' do
          create(:user_preference, user:, budget: 'budget_conscious')
          get preferences_path, as: :json
          json = JSON.parse(response.body)
          expect(json['preferences']['budget']).to eq('budget_conscious')
        end

        it 'handles luxury budget' do
          create(:user_preference, user:, budget: 'luxury')
          get preferences_path, as: :json
          json = JSON.parse(response.body)
          expect(json['preferences']['budget']).to eq('luxury')
        end

        it 'handles different accommodation types' do
          %w[hotel airbnb hostel resort camping].each do |accommodation|
            UserPreference.where(user:).destroy_all
            create(:user_preference, user:, accommodation:)
            get preferences_path, as: :json
            json = JSON.parse(response.body)
            expect(json['preferences']['accommodation']).to eq(accommodation)
          end
        end

        it 'handles different eating habits' do
          %w[restaurants_only self_prepared mix].each do |eating_habit|
            UserPreference.where(user:).destroy_all
            create(:user_preference, user:, eating_habits: eating_habit)
            get preferences_path, as: :json
            json = JSON.parse(response.body)
            expect(json['preferences']['eating_habits']).to eq(eating_habit)
          end
        end

        it 'handles multiple activities' do
          activities = 'outdoors,sightseeing,cultural,relaxation,adventure,nightlife,shopping'
          create(:user_preference, user:, activities:)
          get preferences_path, as: :json
          json = JSON.parse(response.body)
          expect(json['preferences']['activities']).to eq(activities)
        end
      end
    end
  end
end

