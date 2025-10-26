# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for GeneratedPlan resource (list view)
  # Represents generated plan data without full content (for list endpoints)
  # Derived from: generated_plans table
  class GeneratedPlanDTO < T::Struct
    extend T::Sig
    include BaseDTO

    # Core attributes from generated_plans table
    const :id, Integer
    const :trip_id, Integer
    const :status, String # One of: 'pending', 'generating', 'completed', 'failed'
    const :rating, T.nilable(Integer) # 1-10, nullable
    const :created_at, String # ISO 8601 datetime format
    const :updated_at, String # ISO 8601 datetime format

    # Content preview (first 100 characters of content for list view)
    const :content_preview, T.nilable(String), default: nil

    sig { params(plan: GeneratedPlan).returns(GeneratedPlanDTO) }
    def self.from_model(plan)
      new(
        id: plan.id,
        trip_id: plan.trip_id,
        status: plan.status,
        rating: plan.rating,
        created_at: plan.created_at.iso8601,
        updated_at: plan.updated_at.iso8601
      )
    end

    sig { params(plan: GeneratedPlan).returns(GeneratedPlanDTO) }
    def self.from_model_with_preview(plan)
      preview = if plan.content.present? && plan.status == 'completed'
                  # Extract first line or first 100 chars from JSON content
                  content_text = JSON.parse(plan.content).dig('summary', 'description') rescue nil
                  content_text&.truncate(100)
      end

      new(
        id: plan.id,
        trip_id: plan.trip_id,
        status: plan.status,
        rating: plan.rating,
        created_at: plan.created_at.iso8601,
        updated_at: plan.updated_at.iso8601,
        content_preview: preview
      )
    end
  end
end
