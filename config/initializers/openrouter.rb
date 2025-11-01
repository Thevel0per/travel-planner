# frozen_string_literal: true

# OpenRouter API configuration
Rails.application.config.after_initialize do
  OpenRouter.configure do |config|
    # API key from Rails credentials (can be nil in test environment)
    config.api_key = Rails.application.credentials.dig(:openrouter, :api_key) || ENV['OPENROUTER_API_KEY'] || 'test-key'

    # Request timeout in seconds
    config.timeout = 60

    # Maximum number of retries for failed requests
    config.max_retries = 3

    # Logger for debugging and monitoring
    config.logger = Rails.logger

    # API URL (can be overridden for testing)
    config.api_url = 'https://openrouter.ai/api/v1/chat/completions'
  end
end
