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
      begin
        response = OpenRouter::Client.new.chat_completion_with_schema(
          messages: prompt_builder.build_messages,
          schema: TravelPlanGeneration::SchemaBuilder.build
        )
      rescue => e
        Rails.logger.error("ERROR: Failed to call OpenRouter API: #{e.class.name}: #{e.message}")
        Rails.logger.error(e.backtrace.first(10).join("\n"))
        generated_plan.mark_as_failed!
        return ServiceResult.failure(
          error_message: "API call failed: #{e.message}",
          retryable: true
        )
      end

      if response.success?
        result = process_response(response)

        if result.success?
          generated_plan.mark_as_completed!(result.data.to_json_string)
        else
          Rails.logger.error("ERROR: Plan processing failed: #{result.error_message}")
          generated_plan.mark_as_failed!
        end

        result
      else
        error_msg = response.error&.message || 'Unknown error'
        Rails.logger.error("ERROR: OpenRouter API returned error: #{error_msg}")
        generated_plan.mark_as_failed!
        ServiceResult.failure(
          error_message: error_msg,
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
      begin
        plan_content = Schemas::GeneratedPlanContent.from_json(response.content || '{}')
      rescue => e
        error_msg = "Failed to parse plan content: #{e.message}"
        Rails.logger.error("ERROR: #{error_msg}")
        Rails.logger.error("ERROR: Backtrace: #{e.backtrace.first(10).join("\n")}")
        Rails.logger.error("ERROR: Response content (first 500 chars): #{response.content&.first(500)}")
        return ServiceResult.failure(
          error_message: "Failed to parse response: #{e.message}",
          retryable: true
        )
      end

      # Validate
      plan_validator = TravelPlanGeneration::PlanValidator.new(trip:, plan: plan_content)
      validation_errors = plan_validator.validate

      if validation_errors.any?
        Rails.logger.warn("Plan validation errors: #{validation_errors.join(', ')}")
        # Validation errors are retryable - the AI might fix them on retry
        return ServiceResult.failure(
          error_message: "Invalid plan: #{validation_errors.join(', ')}",
          retryable: true
        )
      end

      ServiceResult.success(data: plan_content)
    rescue JSON::ParserError => e
      Rails.logger.error("JSON parse error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      ServiceResult.failure(
        error_message: "Failed to parse response: #{e.message}",
        retryable: true
      )
    rescue StandardError => e
      Rails.logger.error("Processing error: #{e.class.name}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
      ServiceResult.failure(
        error_message: "Processing error: #{e.message}",
        retryable: true
      )
    end
  end
end
