# frozen_string_literal: true

# Serializer for error responses
# Handles ActiveModel::Errors, string messages, and hash structures
class ErrorSerializer < Blueprinter::Base
  field :errors

  class << self
    # Render a single error message
    # @param message [String] The error message
    # @return [String] JSON string
    def render_error(message)
      render_as_hash({ errors: { base: [message] } })
    end

    # Render ActiveModel validation errors
    # @param model [ActiveRecord::Base] Model with validation errors
    # @return [String] JSON string
    def render_model_errors(model)
      render_as_hash({ errors: model.errors.messages })
    end

    # Render custom error hash
    # @param errors [Hash] Hash of field => array of messages
    # @return [String] JSON string
    def render_errors(errors)
      render_as_hash({ errors: errors })
    end
  end
end
