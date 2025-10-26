# typed: strict
# frozen_string_literal: true

module Commands
  # Options for plan generation
  class GenerationOptionsSchema < T::Struct
    include BaseDTO
    extend T::Sig

    const :include_budget_breakdown, T::Boolean, default: true
    const :include_restaurants, T::Boolean, default: true
  end

  # Command Model for creating a new generated plan
  # Used by POST /trips/:trip_id/generated_plans endpoint
  # All fields are optional
  class GeneratedPlanCreateCommand < T::Struct
    include BaseDTO
    extend T::Sig

    const :options, T.nilable(GenerationOptionsSchema), default: nil

    sig { params(params: T::Hash[T.untyped, T.untyped]).returns(GeneratedPlanCreateCommand) }
    def self.from_params(params)
      generated_plan_params = params[:generated_plan] || params
      options_params = generated_plan_params[:options]

      options = if options_params
                  GenerationOptionsSchema.new(
                    include_budget_breakdown: options_params[:include_budget_breakdown] || true,
                    include_restaurants: options_params[:include_restaurants] || true
                  )
      end

      new(options:)
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_generation_options
      if options
        {
          include_budget_breakdown: options.include_budget_breakdown,
          include_restaurants: options.include_restaurants
        }
      else
        {
          include_budget_breakdown: true,
          include_restaurants: true
        }
      end
    end
  end
end
