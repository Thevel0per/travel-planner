# typed: strict
# frozen_string_literal: true

class TripsController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated before accessing any trip actions
  before_action :authenticate_user!

  # GET /trips
  # Lists all trips for the authenticated user with pagination, filtering, and sorting
  # Supports both HTML and JSON formats
  sig { void }
  def index
    # Initialize query service with current user and parameters
    query_service = TripsQueryService.new(current_user, params)

    # Paginate using query service (validates, builds query, and paginates)
    result = apply_pagination(query_service)
    return unless result # Early return if validation fails

    @pagy, @trips = result

    # Respond based on requested format
    respond_to do |format|
      format.html { render :index }
      format.json do
        render_paginated_json(
          @trips,
          dto_class: DTOs::TripDTO,
          pagy: @pagy,
          transform_method: :from_model_with_counts,
          key: :trips
        )
      end
    end
  end

  # POST /trips
  # Creates a new trip for the authenticated user
  # Accepts trip parameters in request body (nested under 'trip' key or flat)
  # Returns 201 Created with trip data on success, 422 with validation errors on failure
  sig { void }
  def create
    # Extract parameters using command object
    command = Commands::TripCreateCommand.from_params(params.permit!.to_h)

    # Create trip using service object
    service = Trips::Create.new(user: current_user, command:)
    trip = service.call

    if trip.persisted?
      # Success: Return 201 Created with trip DTO
      respond_to do |format|
        format.json do
          dto = DTOs::TripDTO.from_model(trip)
          render json: { trip: dto.serialize }, status: :created
        end
        format.html do
          flash[:notice] = 'Trip created successfully'
          redirect_to trip_path(trip)
        end
      end
    else
      # Validation failure: Return 422 Unprocessable Entity with error details
      respond_to do |format|
        format.json do
          error_dto = DTOs::ErrorResponseDTO.from_model_errors(trip)
          render json: error_dto.serialize, status: :unprocessable_content
        end
        format.html do
          flash[:alert] = format_errors_for_flash(trip.errors.messages.transform_keys(&:to_s))
          redirect_to new_trip_path
        end
      end
    end
  end
end
