# typed: strict
# frozen_string_literal: true

class Trips::NotesController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated
  before_action :authenticate_user!
  before_action :set_trip

  # POST /trips/:trip_id/notes
  # Creates a new note for the trip
  # Returns Turbo Stream response for seamless updates
  sig { void }
  def create
    command = Commands::NoteCreateCommand.from_params(params.permit!.to_h)
    @note = @trip.notes.build(command.to_model_attributes)

    if @note.save
      respond_to do |format|
        format.turbo_stream
        format.json do
          dto = DTOs::NoteDTO.from_model(@note)
          render json: { note: dto.serialize }, status: :created
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_content }
        format.json do
          error_dto = DTOs::ErrorResponseDTO.from_model_errors(@note)
          render json: error_dto.serialize, status: :unprocessable_content
        end
      end
    end
  end

  private

  sig { void }
  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end
end
