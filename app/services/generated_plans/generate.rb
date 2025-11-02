# typed: strict
# frozen_string_literal: true

module GeneratedPlans
  # Service to generate AI-powered travel plans
  # Takes trip_id and user_id, generates the plan
  class Generate
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :trip_id

    sig { returns(Integer) }
    attr_reader :user_id

    sig { returns(T.nilable(Integer)) }
    attr_reader :generated_plan_id

    sig do
      params(
        trip_id: Integer,
        user_id: Integer,
        generated_plan_id: T.nilable(Integer)
      ).void
    end
    def initialize(trip_id:, user_id:, generated_plan_id: nil)
      @trip_id = trip_id
      @user_id = user_id
      @generated_plan_id = generated_plan_id
    end

    # Generate the travel plan
    sig { returns(ServiceResult) }
    def call
      # Use existing plan if provided, otherwise create new one
      generated_plan = if generated_plan_id
                          GeneratedPlan.find(generated_plan_id).tap do |plan|
                            raise ActiveRecord::RecordNotFound unless plan.trip_id == trip_id
                          end
      else
                          trip.generated_plans.find_or_create_by(
                            status: 'pending',
                            content: '{}'
                          )
      end

      # Ensure status is 'generating'
      generated_plan.update!(status: 'generating') unless generated_plan.status == 'generating'

      # Validate
      unless validator.valid?
        generated_plan.mark_as_failed!
        return ServiceResult.failure(
          error_message: validator.errors.join(', '),
          retryable: false
        )
      end

      # Call API
      response = OpenRouter::Client.new.chat_completion_with_schema(
        messages: prompt_builder.build_messages,
        schema: TravelPlanGeneration::SchemaBuilder.build
      )

      if response.success?
        result = process_response(response)

        if result.success?
          generated_plan.mark_as_completed!(result.data.to_json_string)
        else
          generated_plan.mark_as_failed!
        end

        result
      else
        generated_plan.mark_as_failed!
        ServiceResult.failure(
          error_message: response.error&.message || 'Unknown error',
          retryable: response.error&.retryable? || false
        )
      end
    rescue StandardError => e
      generated_plan&.mark_as_failed!
      ServiceResult.failure(
        error_message: "Unexpected error: #{e.message}",
        retryable: false
      )
    end

    private

    sig { returns(T.untyped) }
    def trip
      @trip ||= Trip.includes(:notes).find_by!(id: trip_id, user_id:)
    end

    sig { returns(T.untyped) }
    def user_preferences
      @user_preferences ||= User.find(user_id).user_preference
    end

    sig { returns(T::Array[T.untyped]) }
    def notes
      @notes ||= trip.notes.to_a
    end

    sig { returns(TravelPlanGeneration::InputValidator) }
    def validator
      @validator ||= T.let(
        TravelPlanGeneration::InputValidator.new(
          trip:,
          user_preferences:,
          notes:
        ),
        T.nilable(TravelPlanGeneration::InputValidator)
      )
    end

    sig { returns(TravelPlanGeneration::PromptBuilder) }
    def prompt_builder
      @prompt_builder ||= T.let(
        TravelPlanGeneration::PromptBuilder.new(
          trip:,
          user_preferences:,
          notes:
        ),
        T.nilable(TravelPlanGeneration::PromptBuilder)
      )
    end

    sig { params(response: OpenRouter::Response).returns(ServiceResult) }
    def process_response(response)
      # Parse JSON
      plan_content = Schemas::GeneratedPlanContent.from_json(response.content || '{}')

      # Validate
      plan_validator = TravelPlanGeneration::PlanValidator.new(trip:, plan: plan_content)
      validation_errors = plan_validator.validate

      if validation_errors.any?
        return ServiceResult.failure(
          error_message: "Invalid plan: #{validation_errors.join(', ')}",
          retryable: true
        )
      end

      ServiceResult.success(data: plan_content)
    rescue JSON::ParserError => e
      ServiceResult.failure(
        error_message: "Failed to parse response: #{e.message}",
        retryable: true
      )
    rescue StandardError => e
      ServiceResult.failure(
        error_message: "Processing error: #{e.message}",
        retryable: true
      )
    end
  end
end
