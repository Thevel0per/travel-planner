# OpenRouter Service Implementation Plan

## Architecture Overview

Build two separate components:

1. **OpenRouter::Client** (`lib/openrouter/`) - Generic HTTP client for OpenRouter API
2. **TravelPlanGenerationService** (`app/services/`) - Domain service that uses the client to generate travel plans

**Key Principle**: The client knows nothing about travel plans. The service knows nothing about HTTP.

---

## Part 1: OpenRouter::Client (Generic API Client)

### Purpose
Reusable library for communicating with OpenRouter API. Handles HTTP, retries, errors. Can be used for any future OpenRouter integration.

### Public Interface

```ruby
# Initialize
client = OpenRouter::Client.new(
  api_key: 'optional',      # defaults to credentials
  timeout: 60,              # seconds
  max_retries: 3
)

# Make structured completion request
response = client.chat_completion_with_schema(
  model: 'openai/gpt-4o-mini',
  messages: [
    { role: 'system', content: 'You are...' },
    { role: 'user', content: 'Generate...' }
  ],
  schema: { type: 'object', properties: {...} },
  temperature: 0.7,
  max_tokens: 4000
)

# Check result
if response.success?
  data = response.content_as_json  # Parsed JSON
  tokens = response.usage['total_tokens']
else
  error = response.error
  puts error.message
  retry if error.retryable?
end
```

### What It Must Handle

1. **HTTP Communication**
   - POST to `https://openrouter.ai/api/v1/chat/completions`
   - Authorization header with API key
   - JSON request/response
   - Timeout configuration

2. **Structured Responses**
   - Build `response_format` parameter correctly:
     ```ruby
     {
       type: 'json_schema',
       json_schema: {
         name: 'schema_name',
         strict: true,
         schema: { ... }
       }
     }
     ```

3. **Error Handling**
   - Network errors (timeout, connection failed)
   - API errors (401, 403, 429, 500, etc.)
   - Parse errors (invalid JSON)
   - Categorize errors with specific error classes

4. **Retry Logic**
   - Retry on 5xx errors (exponential backoff)
   - Retry on timeouts
   - Respect Retry-After header for 429 (rate limits)
   - Don't retry on 4xx errors (except 429)
   - Max 3 retries by default

5. **Response Parsing**
   - Extract content from: `response['choices'][0]['message']['content']`
   - Extract usage: `response['usage']`
   - Return structured Response object

### Implementation Notes

- Use Ruby's `Net::HTTP` (no extra gems needed)
- Store API key in Rails credentials: `openrouter.api_key`
- Configuration via `config/initializers/openrouter.rb`
- Sanitize API keys from logs
- Add Sorbet type signatures

### File Structure
```
lib/openrouter/
├── client.rb           # Main client class
├── response.rb         # Response wrapper
├── error.rb           # Error class hierarchy
└── configuration.rb   # Config management
```

---

## Part 2: TravelPlanGenerationService

### Purpose
Generate travel plans using OpenRouter. Handles prompt construction, schema definition, and result validation.

### Public Interface

```ruby
# Initialize
service = TravelPlanGenerationService.new(
  trip: trip,
  user_preferences: preferences,
  notes: notes,
  client: optional_client  # for testing
)

# Validate inputs
unless service.valid?
  puts service.errors
  return
end

# Generate plan
result = service.call

# Use result
if result.success?
  plan_content = result.plan_content  # Schemas::GeneratedPlanContent
  plan.update!(
    status: 'completed',
    content: plan_content.to_json_string
  )
else
  puts result.error_message
  retry if result.retryable?
end
```

### What It Must Do

1. **Input Validation**
   - Trip has destination, valid dates, positive group size
   - User preferences exist
   - Notes array not nil (can be empty)

2. **Prompt Construction**
   - **System Message**: Define AI as travel planning expert, specify output format (JSON schema), quality requirements (realistic costs, 0-5 ratings)
   - **User Message**: Format trip details, preferences (budget/accommodation/activities/eating), notes, and explicit request for itinerary

3. **Schema Definition**
   - Build JSON Schema matching `Schemas::GeneratedPlanContent`
   - Set `strict: true` for validation
   - Structure: `{ summary: {...}, daily_itinerary: [{day, date, activities: [...], restaurants: [...]}] }`

4. **API Call**
   - Use injected client or create default
   - Call `client.chat_completion_with_schema`
   - Pass: model (gpt-4o-mini), messages, schema, temp (0.7), max_tokens (4000)

5. **Response Processing**
   - Parse JSON content to `Schemas::GeneratedPlanContent`
   - Validate: duration matches trip, costs consistent, all days have activities
   - Return Result object with plan or error

6. **Error Handling**
   - Translate client errors to domain errors
   - Validation errors (bad input)
   - Generation errors (API failures)
   - Parsing errors (invalid response)

### Implementation Notes

- Default model: `openai/gpt-4o-mini`
- Default temperature: 0.7
- Default max_tokens: 4000
- Return `Result` object, not exceptions
- No direct HTTP - always use client

---

## Implementation Plan

### Phase 1: OpenRouter Client (Days 1-3)

#### Day 1: Foundation
- Create `lib/openrouter/` structure
- Set up autoloading in `config/application.rb`
- Create error class hierarchy
- Add API key to Rails credentials
- Create configuration initializer
- Set up test files with WebMock

#### Day 2: Core Client
- Implement `OpenRouter::Client` class
- Constructor with configuration
- HTTP client setup with Net::HTTP
- `chat_completion_with_schema` method
- Request payload construction
- Basic error handling
- Unit tests

#### Day 3: Advanced Features
- Response parsing to Response object
- Retry logic with exponential backoff
- Rate limit handling (429 with Retry-After)
- Timeout handling
- Logging (sanitized)
- Integration tests with mocked API
- Test connection method

**Deliverable**: Working, tested generic client

---

### Phase 2: Generation Service (Days 4-6)

#### Day 4: Service Structure
- Create `TravelPlanGenerationService` class
- Constructor with trip/preferences/notes
- Input validation (`valid?`, `errors`)
- Result class
- Helper methods (calculate duration, format data)
- Unit tests

#### Day 5: Prompt Engineering
- Design and implement system message
- Design and implement user message
- Format trip details, preferences, notes
- Build JSON schema from `Schemas::GeneratedPlanContent`
- Manual testing with OpenRouter playground
- Refine prompts based on outputs

#### Day 6: Service Integration
- Integrate OpenRouter client (with dependency injection)
- Implement main `call` method
- Parse response to GeneratedPlanContent
- Business validation (duration, costs, etc.)
- Error handling and translation
- Complete unit tests with mocked client
- Integration tests

**Deliverable**: Working service that generates travel plans

---

### Phase 3: Integration (Days 7-8)

#### Day 7: Background Job
- Create `GenerateTravelPlanJob`
- Load trip data and call service
- Update GeneratedPlan status (pending → generating → completed/failed)
- Handle errors appropriately
- Job tests
- Manual testing

#### Day 8: Controller Integration
- Add/update controller action for plan generation
- Validate authorization
- Create GeneratedPlan record with 'pending' status
- Enqueue job
- Return appropriate response
- Controller tests
- End-to-end manual testing

**Deliverable**: Working generation from UI/API to completed plan

---

### Phase 4: Polish & Deploy (Days 9-10)

#### Day 9: Testing & Documentation
- Comprehensive integration tests
- Test various trip scenarios
- Test error cases
- Performance testing
- Write usage documentation
- Add code documentation
- Update README

#### Day 10: Deployment
- Security review (API keys, logging, input sanitization)
- Set up monitoring (errors, costs, performance)
- Deploy to staging and test
- Deploy to production
- Monitor closely
- Verify costs are reasonable

**Deliverable**: Production-ready implementation

---

## Configuration

### Rails Credentials
```yaml
openrouter:
  api_key: sk-or-v1-...
```

### Initializer (`config/initializers/openrouter.rb`)
```ruby
OpenRouter.configure do |config|
  config.api_key = Rails.application.credentials.dig(:openrouter, :api_key)
  config.timeout = 60
  config.max_retries = 3
  config.logger = Rails.logger
end
```

---

## Testing Strategy

### Client Testing
- **Unit**: Request construction, response parsing, error handling
- **Integration**: Mocked HTTP with WebMock/VCR
- **Scenarios**: Success, errors (401/429/500), timeouts, retries

### Service Testing
- **Unit**: Validation, prompt building, schema generation, formatting
- **Integration**: Mocked client, various trip configurations
- **E2E**: Real API calls in staging (recorded with VCR)

### Test Helpers
```ruby
# spec/support/openrouter_helpers.rb
def stub_openrouter_success(content:)
  # Stub successful response
end

def stub_openrouter_error(status:)
  # Stub error response
end
```

---

## Error Handling

### Client Errors
- `AuthenticationError` (401) - Invalid API key
- `RateLimitError` (429) - Too many requests
- `ServerError` (5xx) - OpenRouter issues
- `TimeoutError` - Request timeout
- `NetworkError` - Connection issues
- `ResponseParsingError` - Invalid JSON

### Service Errors
- `ValidationError` - Invalid input data
- `GenerationError` - API call failed
- `SchemaValidationError` - Response doesn't match schema
- `ConfigurationError` - Service misconfigured

### Error Response Pattern
```ruby
{
  success: false,
  error_type: :symbol,
  error_message: "User-friendly message",
  retryable?: true/false
}
```

---

## Security Checklist

- [ ] API key in credentials, not code
- [ ] API key not logged
- [ ] Input sanitization (prevent prompt injection)
- [ ] PII sanitized from logs
- [ ] Rate limiting to prevent cost overruns
- [ ] User authorization checked before generation
- [ ] Error messages don't expose internals
- [ ] HTTPS enforced

---

## Success Metrics

**Technical**:
- API success rate: >95%
- Average response time: <30 seconds
- Schema validation success: >98%

**Business**:
- User plan ratings: >7/10
- Cost per generation: <$0.10
- Generation completion rate: >90%

---

## Future Enhancements

- Support for multiple models (fallback strategy)
- Plan refinement based on feedback
- Streaming responses for real-time updates
- Caching for similar requests
- Multi-language support
- Cost optimization via prompt tuning

---

## Quick Reference

### Key Files to Create
```
lib/openrouter/
  client.rb
  response.rb
  error.rb
  configuration.rb

app/services/
  travel_plan_generation_service.rb

app/jobs/
  generate_travel_plan_job.rb

config/initializers/
  openrouter.rb

spec/lib/openrouter/
  client_spec.rb
  
spec/services/
  travel_plan_generation_service_spec.rb
```

### OpenRouter API Essentials

**Endpoint**: `POST https://openrouter.ai/api/v1/chat/completions`

**Auth**: `Authorization: Bearer {api_key}`

**Request**:
```ruby
{
  model: "openai/gpt-4o-mini",
  messages: [...],
  response_format: {
    type: "json_schema",
    json_schema: { name: "...", strict: true, schema: {...} }
  },
  temperature: 0.7,
  max_tokens: 4000
}
```

**Response**:
```ruby
{
  choices: [{ message: { content: "..." } }],
  usage: { total_tokens: 2000 }
}
```

---

This plan provides the structure and key decisions needed to implement both components efficiently without over-specifying implementation details.
