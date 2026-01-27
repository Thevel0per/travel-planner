# frozen_string_literal: true

# Serializer for GeneratedPlan resources
# Basic implementation for Trip associations
# Will be fully implemented in Task 7
class GeneratedPlanSerializer < ApplicationSerializer
  identifier :id

  fields :trip_id, :status, :rating

  # Format timestamps as ISO 8601
  field :created_at do |plan|
    plan.created_at.iso8601
  end

  field :updated_at do |plan|
    plan.updated_at.iso8601
  end

  # Content field - only include if present (for completed plans)
  field :content, if: ->(_, plan, _) { plan.content.present? }
end
