# frozen_string_literal: true

module OpenRouterHelpers
  def stub_openrouter_success(content:, usage: { 'total_tokens' => 100 })
    body = {
      choices: [
        {
          message: {
            content: content.is_a?(String) ? content : content.to_json
          }
        }
      ],
      usage:
    }.to_json

    stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
      .to_return(
        status: 200,
        body:,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_openrouter_error(status:, message: 'Error')
    stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
      .to_return(
        status:,
        body: { error: { message: } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_openrouter_timeout
    stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
      .to_timeout
  end

  def stub_openrouter_rate_limit(retry_after: 5)
    stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
      .to_return(
        status: 429,
        body: { error: { message: 'Rate limit exceeded' } }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'Retry-After' => retry_after.to_s
        }
      )
  end
end

RSpec.configure do |config|
  config.include OpenRouterHelpers
end
