# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Trips::Notes', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:trip) { create(:trip, user:) }
  let(:other_user_trip) { create(:trip, user: other_user) }
  let(:note) { Note.create!(trip:, content: 'Original note content') }

  describe 'PUT/PATCH /trips/:trip_id/notes/:id' do
    context 'when user is not authenticated' do
      it 'redirects to sign in page for HTML requests' do
        put trip_note_path(trip, note), params: { note: { content: 'Updated content' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'returns 401 unauthorized for JSON requests' do
        put trip_note_path(trip, note), params: { note: { content: 'Updated content' } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      context 'with valid parameters' do
        it 'returns 200 OK status for JSON' do
          put trip_note_path(trip, note), params: { note: { content: 'Updated note content' } }, as: :json
          expect(response).to have_http_status(:ok)
        end

        it 'updates the note content' do
          put trip_note_path(trip, note), params: { note: { content: 'Updated note content' } }, as: :json
          note.reload
          expect(note.content).to eq('Updated note content')
        end

        it 'updates the updated_at timestamp' do
          original_updated_at = note.updated_at
          sleep(0.1) # Ensure timestamp difference
          put trip_note_path(trip, note), params: { note: { content: 'Updated note content' } }, as: :json
          note.reload
          expect(note.updated_at).to be > original_updated_at
        end

        it 'returns updated note data in JSON response' do
          put trip_note_path(trip, note), params: { note: { content: 'Updated note content' } }, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('note')
          expect(json['note']['id']).to eq(note.id)
          expect(json['note']['trip_id']).to eq(trip.id)
          expect(json['note']['content']).to eq('Updated note content')
          expect(json['note']).to have_key('created_at')
          expect(json['note']).to have_key('updated_at')
        end

        it 'accepts flat parameter format (without note key)' do
          put trip_note_path(trip, note), params: { content: 'Flat format content' }, as: :json
          expect(response).to have_http_status(:ok)

          note.reload
          expect(note.content).to eq('Flat format content')
        end

        it 'accepts PATCH method' do
          patch trip_note_path(trip, note), params: { note: { content: 'PATCH update' } }, as: :json
          expect(response).to have_http_status(:ok)

          note.reload
          expect(note.content).to eq('PATCH update')
        end

        context 'HTML format' do
          it 'redirects to trip show page with success message' do
            put trip_note_path(trip, note), params: { note: { content: 'Updated content' } }
            expect(response).to redirect_to(trip_path(trip))
            expect(flash[:notice]).to eq('Note updated successfully')
          end
        end

        context 'Turbo Stream format' do
          it 'returns Turbo Stream response' do
            put trip_note_path(trip, note),
                params: { note: { content: 'Updated content' } },
                headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
            expect(response).to have_http_status(:ok)
            expect(response.content_type).to include('text/vnd.turbo-stream.html')
          end

          it 'includes note update in Turbo Stream response' do
            put trip_note_path(trip, note),
                params: { note: { content: 'Updated content' } },
                headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
            expect(response.body).to include("note_#{note.id}")
          end
        end
      end

      context 'with validation errors' do
        it 'returns 422 Unprocessable Entity for blank content' do
          put trip_note_path(trip, note), params: { note: { content: '' } }, as: :json
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns validation errors in JSON format' do
          put trip_note_path(trip, note), params: { note: { content: '' } }, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('errors')
          expect(json['errors']).to have_key('content')
        end

        it 'does not update the note when validation fails' do
          original_content = note.content
          put trip_note_path(trip, note), params: { note: { content: '' } }, as: :json
          note.reload
          expect(note.content).to eq(original_content)
        end

        it 'returns error for content exceeding maximum length' do
          long_content = 'a' * 10_001
          put trip_note_path(trip, note), params: { note: { content: long_content } }, as: :json
          expect(response).to have_http_status(:unprocessable_content)

          json = JSON.parse(response.body)
          expect(json['errors']).to have_key('content')
        end

        context 'HTML format' do
          it 'redirects to trip show page with error message' do
            put trip_note_path(trip, note), params: { note: { content: '' } }
            expect(response).to redirect_to(trip_path(trip))
            expect(flash[:alert]).to be_present
          end
        end

        context 'Turbo Stream format' do
          it 'returns Turbo Stream response with errors' do
            put trip_note_path(trip, note),
                params: { note: { content: '' } },
                headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
            expect(response).to have_http_status(:unprocessable_content)
            expect(response.content_type).to include('text/vnd.turbo-stream.html')
          end
        end
      end

      context 'when trip does not exist' do
        it 'returns 404 Not Found for JSON requests' do
          put trip_note_path(999_999, note), params: { note: { content: 'Updated' } }, as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'returns error response in correct format' do
          put trip_note_path(999_999, note), params: { note: { content: 'Updated' } }, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('errors')
          expect(json['errors']['base']).to include('Resource not found')
        end

        it 'redirects to root with flash message for HTML requests' do
          put trip_note_path(999_999, note), params: { note: { content: 'Updated' } }
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('Resource not found')
        end
      end

      context 'when note does not exist' do
        it 'returns 404 Not Found for JSON requests' do
          put trip_note_path(trip, 999_999), params: { note: { content: 'Updated' } }, as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'returns error response in correct format' do
          put trip_note_path(trip, 999_999), params: { note: { content: 'Updated' } }, as: :json
          json = JSON.parse(response.body)

          expect(json).to have_key('errors')
          expect(json['errors']['base']).to include('Resource not found')
        end
      end

      context 'when trip belongs to different user' do
        let(:other_user_note) { Note.create!(trip: other_user_trip, content: 'Other user note') }

        it 'returns 404 Not Found (prevents unauthorized access)' do
          put trip_note_path(other_user_trip, other_user_note),
              params: { note: { content: 'Hacked content' } },
              as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'does not reveal trip existence through error message' do
          put trip_note_path(other_user_trip, other_user_note),
              params: { note: { content: 'Hacked content' } },
              as: :json
          json = JSON.parse(response.body)

          expect(json['errors']['base']).to include('Resource not found')
        end

        it 'does not update note belonging to another user' do
          original_content = other_user_note.content
          put trip_note_path(other_user_trip, other_user_note),
              params: { note: { content: 'Hacked content' } },
              as: :json
          other_user_note.reload
          expect(other_user_note.content).to eq(original_content)
        end
      end

      context 'when note belongs to different trip' do
        let(:other_trip) { create(:trip, user:) }
        let(:other_trip_note) { Note.create!(trip: other_trip, content: 'Other trip note') }

        it 'returns 404 Not Found (prevents unauthorized access)' do
          put trip_note_path(trip, other_trip_note),
              params: { note: { content: 'Hacked content' } },
              as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'does not update note from different trip' do
          original_content = other_trip_note.content
          put trip_note_path(trip, other_trip_note),
              params: { note: { content: 'Hacked content' } },
              as: :json
          other_trip_note.reload
          expect(other_trip_note.content).to eq(original_content)
        end
      end

      context 'edge cases' do
        it 'handles content with special characters' do
          special_content = "Note with special chars: <>&\"' and unicode: 🎉"
          put trip_note_path(trip, note), params: { note: { content: special_content } }, as: :json
          expect(response).to have_http_status(:ok)

          note.reload
          expect(note.content).to eq(special_content)
        end

        it 'handles content with newlines' do
          multiline_content = "Line 1\nLine 2\nLine 3"
          put trip_note_path(trip, note), params: { note: { content: multiline_content } }, as: :json
          expect(response).to have_http_status(:ok)

          note.reload
          expect(note.content).to eq(multiline_content)
        end

        it 'handles content at maximum length' do
          max_content = 'a' * 10_000
          put trip_note_path(trip, note), params: { note: { content: max_content } }, as: :json
          expect(response).to have_http_status(:ok)

          note.reload
          expect(note.content.length).to eq(10_000)
        end

        it 'handles missing content parameter gracefully' do
          put trip_note_path(trip, note), params: { note: {} }, as: :json
          # Rails Strong Parameters returns 400 Bad Request when required params are missing
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'response format consistency' do
        it 'returns consistent JSON structure' do
          put trip_note_path(trip, note), params: { note: { content: 'Updated' } }, as: :json
          json = JSON.parse(response.body)

          expect(json['note']).to have_key('id')
          expect(json['note']).to have_key('trip_id')
          expect(json['note']).to have_key('content')
          expect(json['note']).to have_key('created_at')
          expect(json['note']).to have_key('updated_at')
        end

        it 'returns ISO 8601 formatted timestamps' do
          put trip_note_path(trip, note), params: { note: { content: 'Updated' } }, as: :json
          json = JSON.parse(response.body)

          expect(json['note']['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
          expect(json['note']['updated_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        end
      end
    end
  end
end
