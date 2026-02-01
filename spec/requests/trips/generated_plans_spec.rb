# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Trips::GeneratedPlans', type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:trip) { create(:trip, user:) }
  let(:other_user_trip) { create(:trip, user: other_user) }

  describe 'POST /trips/:trip_id/generated_plans' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        post trip_generated_plans_path(trip)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        post trip_generated_plans_path(trip), as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'when trip does not exist' do
        it 'returns 404 Not Found for JSON requests' do
          post trip_generated_plans_path(999_999), as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'returns error response in correct format' do
          post trip_generated_plans_path(999_999), as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('errors')
          expect(json['errors']['base']).to include('Resource not found')
        end
      end

      context 'when trip belongs to different user' do
        it 'returns 404 Not Found (prevents unauthorized access)' do
          post trip_generated_plans_path(other_user_trip), as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'does not reveal trip existence through error message' do
          post trip_generated_plans_path(other_user_trip), as: :json
          json = JSON.parse(response.body)

          expect(json['errors']['base']).to include('Resource not found')
        end
      end

      context 'when user preferences are missing' do
        it 'returns 422 Unprocessable Content for JSON requests' do
          post trip_generated_plans_path(trip), as: :json
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns appropriate error message' do
          post trip_generated_plans_path(trip), as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('error')
          expect(json['error']).to include('user preferences')
        end

        it 'returns 422 for Turbo Stream requests' do
          post trip_generated_plans_path(trip), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns error toast in Turbo Stream response' do
          post trip_generated_plans_path(trip), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
          expect(response.body).to include('toast-container')
          expect(response.body).to include('Cannot generate plan without preferences')
          expect(response.body).to include('Set your preferences here')
          expect(response.body).to include(profile_path)
        end
      end

      context 'with user preferences' do
        let!(:user_preference) { create(:user_preference, user:) }

        context 'with valid request' do
          it 'returns 202 Accepted status for JSON' do
            post trip_generated_plans_path(trip), as: :json
            expect(response).to have_http_status(:accepted)
          end

          it 'creates a generated plan with pending status' do
            expect do
              post trip_generated_plans_path(trip), as: :json
            end.to change(GeneratedPlan, :count).by(1)

            plan = GeneratedPlan.last
            expect(plan.trip).to eq(trip)
            expect(plan.status).to eq('pending')
            expect(plan.content).to eq('{}')
          end

          it 'returns generated plan data in JSON response' do
            post trip_generated_plans_path(trip), as: :json
            json = JSON.parse(response.body)

            expect(json).to have_key('generated_plan')
            expect(json).to have_key('message')

            plan_data = json['generated_plan']
            expect(plan_data).to have_key('id')
            expect(plan_data).to have_key('trip_id')
            expect(plan_data).to have_key('status')
            expect(plan_data).to have_key('created_at')
            expect(plan_data).to have_key('updated_at')
            expect(plan_data['status']).to eq('pending')
            expect(plan_data['trip_id']).to eq(trip.id)
          end

          it 'returns correct message in JSON response' do
            post trip_generated_plans_path(trip), as: :json
            json = JSON.parse(response.body)

            expect(json['message']).to eq('Plan generation initiated. Please check back shortly.')
          end

          it 'queues GeneratedPlanGenerationJob' do
            expect do
              post trip_generated_plans_path(trip), as: :json
            end.to have_enqueued_job(GeneratedPlanGenerationJob)
          end

          it 'queues job with correct parameters' do
            post trip_generated_plans_path(trip), as: :json

            plan = GeneratedPlan.last
            expect(GeneratedPlanGenerationJob).to have_been_enqueued.with(
              generated_plan_id: plan.id,
              user_id: user.id
            )
          end

          it 'returns Turbo Stream response for HTML requests' do
            post trip_generated_plans_path(trip), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
            expect(response).to have_http_status(:accepted)
            expect(response.content_type).to include('text/vnd.turbo-stream.html')
          end

          it 'includes generated plan in Turbo Stream response' do
            post trip_generated_plans_path(trip), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
            expect(response.body).to include('generated_plans_list')
          end

          context 'with generation options' do
            let(:options_params) do
              {
                generated_plan: {
                  options: {
                    include_budget_breakdown: false,
                    include_restaurants: true
                  }
                }
              }
            end

            it 'accepts optional generation options' do
              post trip_generated_plans_path(trip), params: options_params, as: :json
              expect(response).to have_http_status(:accepted)
            end

            it 'creates plan regardless of options (options not yet used)' do
              expect do
                post trip_generated_plans_path(trip), params: options_params, as: :json
              end.to change(GeneratedPlan, :count).by(1)
            end
          end
        end

        context 'error handling' do
          it 'handles validation errors gracefully' do
            # Force a validation error by creating a completed plan without content
            invalid_plan = GeneratedPlan.new(trip:, status: 'completed', content: nil)
            invalid_plan.valid? # Trigger validations to populate errors

            # Stub the association proxy's create! method
            # The controller uses @trip.generated_plans.create!, so we need to stub the association
            allow_any_instance_of(Trip).to receive_message_chain(:generated_plans, :create!).and_raise(
              ActiveRecord::RecordInvalid.new(invalid_plan)
            )

            post trip_generated_plans_path(trip), as: :json
            expect(response).to have_http_status(:unprocessable_content)

            json = JSON.parse(response.body)
            # When create! raises before assignment, controller returns 'error' key
            expect(json).to have_key('error')
            expect(json['error']).to eq('Invalid generated plan parameters')
          end
        end

        context 'when job queue fails' do
          before do
            allow(GeneratedPlanGenerationJob).to receive(:perform_later).and_raise(
              ActiveJob::SerializationError.new('Serialization failed')
            )
          end

          it 'returns 500 Internal Server Error' do
            post trip_generated_plans_path(trip), as: :json
            expect(response).to have_http_status(:internal_server_error)
          end

          it 'marks plan as failed' do
            post trip_generated_plans_path(trip), as: :json
            plan = GeneratedPlan.last
            expect(plan.status).to eq('failed')
          end

          it 'returns generic error message' do
            post trip_generated_plans_path(trip), as: :json
            json = JSON.parse(response.body)

            expect(json).to have_key('error')
            expect(json['error']).to eq('An unexpected error occurred')
          end
        end

        context 'error handling coverage' do
          it 'handles unexpected errors via rescue block' do
            # Stub create! to raise an unexpected error (simulating database failure, etc.)
            allow_any_instance_of(Trip).to receive_message_chain(:generated_plans, :create!).and_raise(
              StandardError.new('Unexpected database error')
            )

            post trip_generated_plans_path(trip), as: :json
            expect(response).to have_http_status(:internal_server_error)

            json = JSON.parse(response.body)
            expect(json).to have_key('error')
            expect(json['error']).to eq('An unexpected error occurred')
          end
        end

        context 'multiple plan creations' do
          it 'allows creating multiple plans for the same trip' do
            expect do
              post trip_generated_plans_path(trip), as: :json
              post trip_generated_plans_path(trip), as: :json
            end.to change(GeneratedPlan, :count).by(2)

            plans = trip.generated_plans.reload
            expect(plans.count).to eq(2)
            expect(plans.pluck(:status)).to all(eq('pending'))
          end

          it 'queues separate jobs for each plan' do
            expect do
              post trip_generated_plans_path(trip), as: :json
              post trip_generated_plans_path(trip), as: :json
            end.to have_enqueued_job(GeneratedPlanGenerationJob).exactly(2).times
          end
        end
      end
    end
  end
end
