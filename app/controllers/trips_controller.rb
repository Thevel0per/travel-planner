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
end
