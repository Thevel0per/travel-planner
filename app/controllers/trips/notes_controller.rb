# typed: strict
# frozen_string_literal: true

class Trips::NotesController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_note, only: [ :update, :destroy ]

  # POST /trips/:trip_id/notes
  # Creates a new note for the trip
  # Returns Turbo Stream response for seamless updates
  sig { void }
  def create
    command = Commands::NoteCreateCommand.from_params(params.permit!.to_h)
    @note = @trip.notes.build(command.to_model_attributes)

    if @note.save
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Note added successfully'
        end
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

  # PUT/PATCH /trips/:trip_id/notes/:id
  # Updates an existing note for the trip
  # Returns updated note data in JSON or Turbo Stream format
  sig { void }
  def update
    command = Commands::NoteUpdateCommand.from_params(params.permit!.to_h)
    attributes = command.to_model_attributes

    if @note.update(attributes)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Note updated successfully'
        end
        format.json do
          dto = DTOs::NoteDTO.from_model(@note)
          render json: { note: dto.serialize }, status: :ok
        end
        format.html do
          flash[:notice] = 'Note updated successfully'
          redirect_to trip_path(@trip)
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render :update, status: :unprocessable_content }
        format.json do
          error_dto = DTOs::ErrorResponseDTO.from_model_errors(@note)
          render json: error_dto.serialize, status: :unprocessable_content
        end
        format.html do
          flash[:alert] = format_errors_for_flash(@note.errors.to_hash)
          redirect_to trip_path(@trip)
        end
      end
    end
  end

  # DELETE /trips/:trip_id/notes/:id
  sig { void }
  def destroy
    note_id = @note.id
    if @note.destroy
      respond_to do |format|
        format.turbo_stream do
          @note_id = note_id
          flash.now[:notice] = 'Note deleted successfully'
        end
        format.json do
          render json: { message: 'Note deleted successfully' }, status: :ok
        end
        format.html do
          flash[:notice] = 'Note deleted successfully'
          redirect_to trip_path(@trip)
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render :destroy, status: :unprocessable_content }
        format.json do
          error_dto = DTOs::ErrorResponseDTO.single_error('Failed to delete note')
          render json: error_dto.serialize, status: :unprocessable_content
        end
        format.html do
          flash[:alert] = 'Failed to delete note'
          redirect_to trip_path(@trip)
        end
      end
    end
  end

  private

  sig { void }
  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  sig { void }
  def set_note
    @note = @trip.notes.find(params[:id])
  end
end
