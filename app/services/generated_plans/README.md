# Generated Plans Services

Services for AI-generated travel plans.

## `GeneratedPlans::Generate`

Generates AI-powered travel itineraries.

**Usage:**
```ruby
service = GeneratedPlans::Generate.new(
  trip_id: trip.id,
  user_id: current_user.id
)

result = service.call

if result.success?
  plan_content = result.data  # Hash with symbolized keys
  generated_plan.mark_as_completed!(plan_content.to_json)
elsif result.retryable?
  # Retry later
  RetryGenerationJob.perform_later(trip_id)
else
  # Permanent failure
  generated_plan.mark_as_failed!
end
```

**Returns:** `ServiceResult`
- `success?` - Whether generation succeeded
- `failure?` - Whether generation failed
- `retryable?` - Whether error is retryable (use OpenRouter client's logic)
- `data` - Generated plan as Hash with symbolized keys on success
- `error_message` - Error description on failure

**Flow:**
1. Load trip (verify ownership)
2. Load user preferences
3. Validate inputs
4. Call OpenRouter API
5. Validate output
6. Return result

Simple and clean. No fancy error mapping, just uses the OpenRouter client's retry logic.
