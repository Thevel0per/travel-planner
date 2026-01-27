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
    @note = @trip.notes.build(note_params)

    if @note.save
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Note added successfully'
        end
        format.json do
          render json: { note: NoteSerializer.render_as_hash(@note) }, status: :created
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_content }
        format.json do
          render json: ErrorSerializer.render_model_errors(@note), status: :unprocessable_content
        end
      end
    end
  end

  # PUT/PATCH /trips/:trip_id/notes/:id
  # Updates an existing note for the trip
  # Returns updated note data in JSON or Turbo Stream format
  sig { void }
  def update
    if @note.update(note_params)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Note updated successfully'
        end
        format.json do
          render json: { note: NoteSerializer.render_as_hash(@note) }, status: :ok
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
          render json: ErrorSerializer.render_model_errors(@note), status: :unprocessable_content
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
          render json: ErrorSerializer.render_error('Failed to delete note'), status: :unprocessable_content
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

  # Strong Parameters for Note
  sig { returns(ActionController::Parameters) }
  def note_params
    params.require(:note).permit(:content)
  end
end
