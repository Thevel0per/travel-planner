# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for GeneratedPlan resource (detail view)
  # Represents generated plan data with full structured content (for show endpoint)
  # Derived from: generated_plans table with parsed content
  class GeneratedPlanDetailDTO < T::Struct
    extend T::Sig
    include BaseDTO

    # Core attributes from generated_plans table
    const :id, Integer
    const :trip_id, Integer
    const :status, String # One of: 'pending', 'generating', 'completed', 'failed'
    const :rating, T.nilable(Integer) # 1-10, nullable
    const :created_at, String # ISO 8601 datetime format
    const :updated_at, String # ISO 8601 datetime format

    # Full structured content (only present when status is 'completed')
    const :content, T.nilable(Schemas::GeneratedPlanContent), default: nil

    sig { params(plan: GeneratedPlan).returns(GeneratedPlanDetailDTO) }
    def self.from_model(plan)
      content = if plan.status == 'completed' && plan.content.present?
                  Schemas::GeneratedPlanContent.from_json(plan.content)
      end

      new(
        id: plan.id,
        trip_id: plan.trip_id,
        status: plan.status,
        rating: plan.rating,
        created_at: plan.created_at.iso8601,
        updated_at: plan.updated_at.iso8601,
        content:
      )
    end
  end
end
