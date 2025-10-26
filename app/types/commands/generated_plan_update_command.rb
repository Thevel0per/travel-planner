# typed: strict
# frozen_string_literal: true

module Commands
  # Command Model for updating a generated plan (primarily for rating)
  # Used by PATCH /trips/:trip_id/generated_plans/:id endpoint
  # Derived from: generated_plans table (subset of fields)
  class GeneratedPlanUpdateCommand < T::Struct
    include BaseDTO
    extend T::Sig

    const :rating, T.nilable(Integer), default: nil # 1-10

    sig { params(params: T::Hash[T.untyped, T.untyped]).returns(GeneratedPlanUpdateCommand) }
    def self.from_params(params)
      generated_plan_params = params[:generated_plan] || params
      new(rating: generated_plan_params[:rating])
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_model_attributes
      attributes = {}
      attributes[:rating] = rating if rating
      attributes
    end
  end
end
