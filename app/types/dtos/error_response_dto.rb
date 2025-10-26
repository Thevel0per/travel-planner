# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for API error responses
  # Used for validation errors and general error messages
  class ErrorResponseDTO < T::Struct
    extend T::Sig
    include BaseDTO

    # Single error message (for general errors)
    const :error, T.nilable(String), default: nil

    # Field-specific validation errors (hash of field_name => array of error messages)
    const :errors, T.nilable(T::Hash[String, T::Array[String]]), default: nil

    sig { params(message: String).returns(ErrorResponseDTO) }
    def self.single_error(message)
      new(error: message)
    end

    sig { params(errors_hash: T::Hash[String, T::Array[String]]).returns(ErrorResponseDTO) }
    def self.validation_errors(errors_hash)
      new(errors: errors_hash)
    end

    sig { params(model: T.untyped).returns(ErrorResponseDTO) }
    def self.from_model_errors(model)
      # Convert ActiveModel::Errors to hash format
      errors_hash = model.errors.messages.transform_keys(&:to_s).transform_values do |messages|
        messages.map(&:to_s)
      end
      new(errors: errors_hash)
    end
  end
end
