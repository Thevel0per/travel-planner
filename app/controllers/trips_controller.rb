# typed: strict
# frozen_string_literal: true

class TripsController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated before accessing any trip actions
  before_action :authenticate_user!
  before_action :set_trip, only: [ :show, :update, :destroy, :edit ]

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
        render json: {
          trips: TripSerializer.render_as_hash(@trips, include_counts: true),
          meta: PaginationSerializer.from_pagy(@pagy)
        }, status: :ok
      end
    end
  end

  # GET /trips/new
  # Displays form for creating a new trip
  sig { void }
  def new
    @trip = current_user.trips.new
  end

  # GET /trips/:id/edit
  # Displays form for editing an existing trip
  sig { void }
  def edit; end

  # GET /trips/:id
  # Retrieves a specific trip with its notes and generated plans for the authenticated user
  # Returns 200 OK with trip data on success, 404 on not found
  sig { void }
  def show
    # Respond based on requested format
    respond_to do |format|
      format.json do
        render json: { trip: TripSerializer.render_as_hash(@trip, include_associations: true) }, status: :ok
      end
      format.html { render :show }
    end
  end

  # POST /trips
  # Creates a new trip for the authenticated user
  # Accepts trip parameters in request body (nested under 'trip' key or flat)
  # Returns 201 Created with trip data on success, 422 with validation errors on failure
  sig { void }
  def create
    # Create trip using service object with strong parameters
    service = Trips::Create.new(user: current_user, attributes: trip_params.to_h.symbolize_keys)
    trip = service.call

    if trip.persisted?
      # Success: Return 201 Created with trip
      respond_to do |format|
        format.json do
          render json: { trip: TripSerializer.render_as_hash(trip) }, status: :created
        end
        format.html do
          flash[:notice] = 'Trip created successfully'
          redirect_to trip_path(trip)
        end
      end
    else
      # Validation failure: Return 422 Unprocessable Entity with error details
      @trip = trip
      respond_to do |format|
        format.json do
          render json: ErrorSerializer.render_model_errors(trip), status: :unprocessable_content
        end
        format.html do
          render :new, status: :unprocessable_content
        end
      end
    end
  end

  # PUT/PATCH /trips/:id
  # Updates an existing trip for the authenticated user
  # Supports partial updates (all fields optional)
  # Returns 200 OK with updated trip data on success, 422 with validation errors on failure
  sig { void }
  def update
    # Update trip with strong parameters
    # ActiveRecord will run model validations automatically
    if @trip.update(trip_params)
      # Success: Return 200 OK with updated trip
      respond_to do |format|
        format.json do
          render json: { trip: TripSerializer.render_as_hash(@trip) }, status: :ok
        end
        format.html do
          flash[:notice] = 'Trip updated successfully'
          redirect_to trip_path(@trip)
        end
      end
    else
      # Validation failure: Return 422 Unprocessable Entity with error details
      respond_to do |format|
        format.json do
          render json: ErrorSerializer.render_model_errors(@trip), status: :unprocessable_content
        end
        format.html do
          render :edit, status: :unprocessable_content
        end
      end
    end
  end

  # DELETE /trips/:id
  # Deletes an existing trip for the authenticated user
  # Cascades deletion to all associated notes and generated plans
  # Returns 200 OK with success message on success, 404 on not found
  sig { void }
  def destroy
    @trip.destroy

    respond_to do |format|
      format.json do
        render json: { message: 'Trip deleted successfully' }, status: :ok
      end
      format.html do
        flash[:notice] = 'Trip deleted successfully'
        redirect_to trips_path
      end
    end
  end

  private

  sig { void }
  def set_trip
    if action_name == 'show'
      @trip = current_user.trips.includes(:notes, :generated_plans).find(params[:id])
    else
      @trip = current_user.trips.find(params[:id])
    end
  end

  # Strong Parameters for Trip
  sig { returns(ActionController::Parameters) }
  def trip_params
    params.require(:trip).permit(:name, :destination, :start_date, :end_date, :number_of_people)
  end
end
