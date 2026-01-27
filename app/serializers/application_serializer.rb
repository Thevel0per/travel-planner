# frozen_string_literal: true

# Base serializer for all API responses
# Inherit from this class to maintain consistency and enable future shared behavior
class ApplicationSerializer < Blueprinter::Base
  # This class currently provides no additional functionality beyond Blueprinter::Base,
  # but serves as a conventional base class for potential future shared behavior such as:
  # - Custom transformers or formatters
  # - Authorization checks
  # - Logging or metrics
end
