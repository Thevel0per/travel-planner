# OpenRouter Client

A Ruby client library for the OpenRouter API, providing structured JSON responses with automatic retry logic and comprehensive error handling.

## Installation

The client is automatically loaded with the Rails application. Configure it in `config/initializers/openrouter.rb`.

## Configuration

Add your API key to Rails credentials:

```bash
EDITOR="nano" bin/rails credentials:edit
```

Add:

```yaml
openrouter:
  api_key: sk-or-v1-your-api-key-here
```

## Usage

### Basic Example

```ruby
# Initialize client
client = OpenRouter::Client.new

# Make a chat completion request with JSON schema
response = client.chat_completion_with_schema(
  model: 'openai/gpt-4o-mini',
  messages: [
    { 'role' => 'system', 'content' => 'You are a helpful assistant.' },
    { 'role' => 'user', 'content' => 'What is the weather like?' }
  ],
  schema: {
    'type' => 'object',
    'properties' => {
      'weather' => { 'type' => 'string' },
      'temperature' => { 'type' => 'number' }
    },
    'required' => ['weather']
  },
  temperature: 0.7,
  max_tokens: 1000
)

# Check result
if response.success?
  data = response.content_as_json
  puts "Weather: #{data['weather']}"
  puts "Tokens used: #{response.total_tokens}"
else
  puts "Error: #{response.error.message}"
  retry if response.error.retryable?
end
```

### Custom Configuration

```ruby
client = OpenRouter::Client.new(
  api_key: 'custom-key',
  timeout: 30,
  max_retries: 5
)
```

### Testing Connection

```ruby
if client.test_connection
  puts "Successfully connected to OpenRouter"
else
  puts "Connection failed"
end
```

## Response Object

The `OpenRouter::Response` object provides:

- `success?` / `failure?` - Check if request succeeded
- `content` - Raw response content (JSON string)
- `content_as_json` - Parsed JSON content
- `usage` - Token usage information
- `total_tokens` - Total tokens used
- `prompt_tokens` - Tokens in prompt
- `completion_tokens` - Tokens in completion
- `error` - Error object (if failed)
- `raw_response` - Full API response

## Error Handling

The client handles various error types:

### Error Classes

- `OpenRouter::AuthenticationError` (401) - Invalid API key (not retryable)
- `OpenRouter::RateLimitError` (429) - Rate limit exceeded (retryable)
- `OpenRouter::ServerError` (5xx) - Server issues (retryable)
- `OpenRouter::TimeoutError` - Request timeout (retryable)
- `OpenRouter::NetworkError` - Connection issues (retryable)
- `OpenRouter::ResponseParsingError` - Invalid JSON (not retryable)
- `OpenRouter::ClientError` (4xx) - Client errors (not retryable)
- `OpenRouter::ConfigurationError` - Invalid configuration (not retryable)

### Retry Logic

The client automatically retries on:
- Rate limits (429) - respects `Retry-After` header
- Server errors (5xx) - exponential backoff
- Timeouts - exponential backoff
- Network errors - exponential backoff

Non-retryable errors return immediately.

## Testing

Use WebMock to stub API requests in tests:

```ruby
require 'webmock/rspec'

RSpec.describe MyService do
  include OpenRouterHelpers

  it 'handles successful response' do
    stub_openrouter_success(content: '{"result": "success"}')
    
    # Your test code
  end

  it 'handles errors' do
    stub_openrouter_error(status: 500)
    
    # Your test code
  end
end
```

## Security

- API keys are stored in Rails credentials (encrypted)
- API keys are filtered from logs automatically
- All requests use HTTPS
- Input sanitization recommended to prevent prompt injection

## Performance

- Default timeout: 60 seconds
- Default max retries: 3
- Exponential backoff: 2^attempt seconds (max 32s)
- Rate limit handling: Respects `Retry-After` header

## Logging

Set logger in configuration:

```ruby
OpenRouter.configure do |config|
  config.logger = Rails.logger
end
```

Logs include:
- Retry attempts with backoff times
- Errors (sanitized, no API keys)

## Examples

See `spec/lib/openrouter/client_spec.rb` for comprehensive usage examples.

