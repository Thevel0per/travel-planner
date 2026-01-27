# frozen_string_literal: true

# Configure Blueprinter for JSON serialization
require 'blueprinter'

Blueprinter.configure do |config|
  # Format datetime fields in ISO 8601 format
  config.datetime_format = ->(datetime) { datetime&.iso8601 }

  # Sort JSON keys for consistency (helpful for testing)
  config.sort_fields_by = :definition
end
