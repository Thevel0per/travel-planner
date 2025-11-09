# typed: strict
# frozen_string_literal: true

class Trips::GeneratedPlansController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated
  before_action :authenticate_user!
  before_action :set_trip

  # GET /trips/:trip_id/generated_plans/:id
  # Displays a detailed view of a generated plan
  # Returns 200 OK with full plan details (HTML or JSON)
  sig { void }
  def show
    @generated_plan_model = @trip.generated_plans.find(params[:id])
    @generated_plan = DTOs::GeneratedPlanDetailDTO.from_model(@generated_plan_model)

    respond_to do |format|
      format.html # Renders show.html.erb
      format.json do
        render json: {
          generated_plan: @generated_plan.serialize
        }, status: :ok
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("Generated plan not found: #{e.message}")
    respond_to do |format|
      format.html { render :not_found, status: :not_found }
      format.json do
        error_dto = DTOs::ErrorResponseDTO.single_error('Generated plan not found')
        render json: error_dto.serialize, status: :not_found
      end
    end
  end

  # PATCH /trips/:trip_id/generated_plans/:id
  # Updates a generated plan (primarily for rating)
  # Returns 200 OK with updated plan details (HTML Turbo Stream or JSON)
  sig { void }
  def update
    @generated_plan_model = @trip.generated_plans.find(params[:id])

    # Parse command from params
    command = Commands::GeneratedPlanUpdateCommand.from_params(params.permit!.to_h)

    # Update plan
    @generated_plan_model.update!(command.to_model_attributes)

    # Transform to DTO for response
    @generated_plan = DTOs::GeneratedPlanDetailDTO.from_model(@generated_plan_model)

    respond_to do |format|
      format.turbo_stream # Renders update.turbo_stream.erb
      format.json do
        render json: {
          generated_plan: @generated_plan.serialize,
          message: 'Rating saved successfully'
        }, status: :ok
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    # Handle validation errors
    Rails.logger.warn("Validation error updating generated plan: #{e.message}")
    @generated_plan = DTOs::GeneratedPlanDetailDTO.from_model(@generated_plan_model)

    respond_to do |format|
      format.turbo_stream { render :update, status: :unprocessable_content }
      format.json do
        error_dto = DTOs::ErrorResponseDTO.from_model_errors(@generated_plan_model)
        render json: error_dto.serialize, status: :unprocessable_content
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("Generated plan not found: #{e.message}")
    respond_to do |format|
      format.turbo_stream { render :update, status: :not_found }
      format.json do
        error_dto = DTOs::ErrorResponseDTO.single_error('Generated plan not found')
        render json: error_dto.serialize, status: :not_found
      end
    end
  end

  # POST /trips/:trip_id/generated_plans
  # Initiates generation of a new travel plan
  # Returns 202 Accepted with plan in 'pending' status
  # Supports both JSON and Turbo Stream responses
  sig { void }
  def create
    # Check if user preferences exist (required for generation)
    unless current_user.user_preference
      error_dto = DTOs::ErrorResponseDTO.single_error(
        'Cannot generate plan without user preferences. Please set your preferences first.'
      )
      respond_to do |format|
        format.json { render json: error_dto.serialize, status: :unprocessable_content }
        format.turbo_stream { render :create, status: :unprocessable_content }
      end
      return
    end

    # Create plan with 'pending' status
    @generated_plan = @trip.generated_plans.create!(
      status: 'pending',
      content: '{}'
    )

    # Queue background job for plan generation
    GeneratedPlanGenerationJob.perform_later(
      generated_plan_id: @generated_plan.id,
      user_id: current_user.id
    )

    respond_to do |format|
      format.turbo_stream { render status: :accepted }
      format.json do
        dto = DTOs::GeneratedPlanDTO.from_model(@generated_plan)
        render json: {
          generated_plan: dto.serialize,
          message: 'Plan generation initiated. Please check back shortly.'
        }, status: :accepted
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    # Handle validation errors from plan creation
    Rails.logger.warn("Validation error creating generated plan: #{e.message}")
    @generated_plan&.mark_as_failed!

    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_content }
      format.json do
        if @generated_plan
          error_dto = DTOs::ErrorResponseDTO.from_model_errors(@generated_plan)
        else
          error_dto = DTOs::ErrorResponseDTO.single_error('Invalid generated plan parameters')
        end
        render json: error_dto.serialize, status: :unprocessable_content
      end
    end
  rescue ActiveJob::SerializationError => e
    # Handle job queue failures
    Rails.logger.error("Job queue error: #{e.message}")
    @generated_plan&.mark_as_failed!

    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_content }
      format.json do
        error_dto = DTOs::ErrorResponseDTO.single_error('An unexpected error occurred')
        render json: error_dto.serialize, status: :internal_server_error
      end
    end
  rescue StandardError => e
    # Handle unexpected errors
    Rails.logger.error("Error creating generated plan: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    @generated_plan&.mark_as_failed!

    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_content }
      format.json do
        error_dto = DTOs::ErrorResponseDTO.single_error('An unexpected error occurred')
        render json: error_dto.serialize, status: :internal_server_error
      end
    end
  end

  private

  sig { void }
  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end
end
