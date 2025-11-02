# typed: strict
# frozen_string_literal: true

class Trips::GeneratedPlansController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated
  before_action :authenticate_user!
  before_action :set_trip

  # POST /trips/:trip_id/generated_plans
  # Initiates generation of a new travel plan
  # Returns Turbo Stream response with new plan in 'pending' or 'generating' status
  sig { void }
  def create
    # Create plan with 'pending' status
    @generated_plan = @trip.generated_plans.create!(
      status: 'pending',
      content: '{}'
    )

    # Trigger background job for plan generation
    # Note: The actual job implementation should be added separately
    # For now, we'll create the plan and update it to 'generating'
    @generated_plan.mark_as_generating!

    # TODO: Queue background job to generate plan
    # GeneratedPlanGenerationJob.perform_later(@generated_plan.id, current_user.id)

    respond_to do |format|
      format.turbo_stream
      format.json do
        dto = DTOs::GeneratedPlanDTO.from_model(@generated_plan)
        render json: { generated_plan: dto.serialize }, status: :accepted
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error creating generated plan: #{e.message}")
    @generated_plan&.mark_as_failed!

    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_content }
      format.json do
        error_dto = DTOs::ErrorResponseDTO.single_error('Failed to initiate plan generation')
        render json: error_dto.serialize, status: :unprocessable_content
      end
    end
  end

  private

  sig { void }
  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end
end
