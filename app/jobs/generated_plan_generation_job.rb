# typed: strict
# frozen_string_literal: true

# Background job to generate AI-powered travel plans asynchronously
# Queued from Trips::GeneratedPlansController#create
class GeneratedPlanGenerationJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(generated_plan_id: Integer, user_id: Integer).void }
  def perform(generated_plan_id:, user_id:)
    generated_plan = GeneratedPlan.find_by(id: generated_plan_id)
    return unless generated_plan

    # Update status to 'generating'
    generated_plan.mark_as_generating!

    # Call the generation service
    service = GeneratedPlans::Generate.new(
      trip_id: generated_plan.trip_id,
      user_id:,
      generated_plan_id: generated_plan.id
    )

    result = service.call

    # Service handles status updates (completed/failed) internally
    unless result.success?
      Rails.logger.error("Plan generation failed for plan #{generated_plan_id}: #{result.error_message}")
    end
  rescue StandardError => e
    Rails.logger.error("Error in GeneratedPlanGenerationJob: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # Mark plan as failed if it still exists
    generated_plan = GeneratedPlan.find_by(id: generated_plan_id)
    generated_plan&.mark_as_failed!
  end
end
