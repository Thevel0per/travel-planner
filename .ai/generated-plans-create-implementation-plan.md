# API Endpoint Implementation Plan: Create Generated Plan

## 1. Endpoint Overview

This endpoint initiates AI-powered travel plan generation for a specific trip. It creates a `GeneratedPlan` record in `pending` status, queues a background job for asynchronous generation, and returns a `202 Accepted` response indicating the generation has been initiated.

**Key Features:**
- Asynchronous plan generation via background job
- User preferences validation (required for generation)
- Optional generation options (include_budget_breakdown, include_restaurants)
- Supports both JSON and Turbo Stream responses

## 2. Request Details

- **HTTP Method:** `POST`
- **URL Structure:** `/trips/:trip_id/generated_plans`
- **Authentication:** Required (Devise session-based)
- **Content-Type:** `application/json` (for JSON requests)

### Parameters:

**Required:**
- `trip_id` (URL parameter) - Must be a valid trip ID belonging to the authenticated user

**Optional:**
- `generated_plan[options][include_budget_breakdown]` (Boolean, default: true)
- `generated_plan[options][include_restaurants]` (Boolean, default: true)

### Request Body Structure:

The request body is optional. If provided, it follows this structure:

```json
{
  "generated_plan": {
    "options": {
      "include_budget_breakdown": true,
      "include_restaurants": true
    }
  }
}
```

If the body is empty or omitted, default values are used for options.

## 3. Used Types

### DTOs:
- **`DTOs::GeneratedPlanDTO`** - Used to serialize the created generated plan in the response
- **`DTOs::ErrorResponseDTO`** - Used for error responses (404, 422, 500)

### Commands:
- **`Commands::GeneratedPlanCreateCommand`** - Parses and validates request parameters
  - Includes nested `GenerationOptionsSchema` for options validation
  - Handles default values for optional options

### Services:
- **`GeneratedPlans::Generate`** - Existing service that performs the actual plan generation (used by background job)

## 4. Response Details

### Success Response (202 Accepted):

```json
{
  "generated_plan": {
    "id": 2,
    "trip_id": 1,
    "status": "pending",
    "rating": null,
    "created_at": "2025-10-19T14:00:00Z",
    "updated_at": "2025-10-19T14:00:00Z"
  },
  "message": "Plan generation initiated. Please check back shortly."
}
```

**Response Headers:**
- `Content-Type: application/json`
- Status: `202 Accepted`

**Note:** For Turbo Stream requests, the response follows the Turbo Stream format defined in `app/views/trips/generated_plans/create.turbo_stream.erb`.

### Error Responses:

#### 404 Not Found (Trip not found):
```json
{
  "error": "Resource not found"
}
```
**Scenario:** Trip ID doesn't exist or doesn't belong to the authenticated user.

#### 422 Unprocessable Content (Missing user preferences):
```json
{
  "error": "Cannot generate plan without user preferences. Please set your preferences first."
}
```
**Scenario:** User has not set up their preferences record. Generation cannot proceed without preferences.

#### 422 Unprocessable Content (Validation error):
```json
{
  "errors": {
    "generated_plan": ["Invalid options provided"]
  }
}
```
**Scenario:** Invalid command parameters (e.g., invalid option values).

#### 500 Internal Server Error:
```json
{
  "error": "An unexpected error occurred"
}
```
**Scenario:** Unexpected server-side errors (database failures, etc.).

## 5. Data Flow

### Request Processing Flow:

```
1. HTTP Request (POST /trips/:trip_id/generated_plans)
   ↓
2. Rails Router → Trips::GeneratedPlansController#create
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. before_action :set_trip (loads trip, handles 404 if not found)
   ↓
5. Parse request parameters → GeneratedPlanCreateCommand
   ↓
6. Validate command (if invalid → 422)
   ↓
7. Check if user preferences exist (if missing → 422)
   ↓
8. Create GeneratedPlan record with status 'pending'
   ↓
9. Queue background job: GeneratedPlanGenerationJob
   ↓
10. Return 202 Accepted with GeneratedPlanDTO + message
```

### Database Operations:

**1. Load Trip (with authorization check):**
```ruby
@trip = current_user.trips.find(params[:trip_id])
# Raises ActiveRecord::RecordNotFound if trip doesn't exist or doesn't belong to user
```

**2. Check User Preferences:**
```ruby
user_preference = current_user.user_preference
# Returns nil if preferences don't exist (triggers 422 error)
```

**3. Create Generated Plan:**
```ruby
@generated_plan = @trip.generated_plans.create!(
  status: 'pending',
  content: '{}'
)
```

**4. Queue Background Job:**
```ruby
GeneratedPlanGenerationJob.perform_later(
  @generated_plan.id,
  current_user.id
)
```

### Background Job Flow:

```
1. GeneratedPlanGenerationJob performs asynchronously
   ↓
2. Job loads GeneratedPlan and updates status to 'generating'
   ↓
3. Job calls GeneratedPlans::Generate service
   ↓
4. Service validates trip, preferences, notes
   ↓
5. Service calls OpenRouter API to generate plan
   ↓
6. On success: Update plan status to 'completed' with content
   ↓
7. On failure: Update plan status to 'failed'
```

## 6. Security Considerations

### Authentication:
- **Devise Integration:** `before_action :authenticate_user!` ensures user is signed in
- **Session-based:** Relies on Devise session cookie
- **Unauthenticated Access:** Redirects to sign-in (HTML) or returns 401 (JSON)

### Authorization:
- **User Scoping:** CRITICAL - Trip must belong to `current_user`
  - Implemented via `current_user.trips.find(params[:trip_id])`
  - Raises `ActiveRecord::RecordNotFound` if trip doesn't exist or belongs to another user
  - Handled by `ApplicationController#handle_not_found` → 404 response

### Input Validation & Sanitization:

**Command Validation:**
- Use `Commands::GeneratedPlanCreateCommand.from_params(params)` to parse and validate
- Options are validated as booleans with defaults
- Invalid options result in 422 error

**SQL Injection Prevention:**
- All queries use ActiveRecord (parameterized queries)
- No raw SQL interpolation

**XSS Prevention:**
- JSON responses are properly serialized via DTOs
- No user input directly rendered in responses
- Rails escapes HTML by default in Turbo Stream views

### HTTPS:
- Ensure production environment enforces HTTPS
- Set `force_ssl = true` in `config/environments/production.rb` (if not already set)

## 7. Error Handling

### Error Scenarios & Status Codes:

| Scenario | Status Code | Response | Handling |
|----------|-------------|----------|----------|
| User not authenticated | 401 Unauthorized | Devise redirect or JSON error | Handled by Devise `authenticate_user!` |
| Trip not found or unauthorized | 404 Not Found | ErrorResponseDTO: "Resource not found" | `ActiveRecord::RecordNotFound` caught by `ApplicationController#handle_not_found` |
| User preferences missing | 422 Unprocessable Content | ErrorResponseDTO: "Cannot generate plan without user preferences..." | Explicit check before plan creation |
| Invalid command parameters | 422 Unprocessable Content | ErrorResponseDTO with validation errors | Command validation fails |
| Database error on create | 500 Internal Server Error | ErrorResponseDTO: "An unexpected error occurred" | Catch `ActiveRecord::RecordInvalid` or other exceptions |
| Background job queue failure | 500 Internal Server Error | ErrorResponseDTO: "An unexpected error occurred" | Catch `ActiveJob::SerializationError` or similar |

### Error Handling Implementation:

**Controller Error Handling:**
```ruby
# StandardError rescue block in controller
rescue StandardError => e
  Rails.logger.error("Error creating generated plan: #{e.message}")
  Rails.logger.error(e.backtrace.join("\n"))
  
  # Mark plan as failed if it was created
  @generated_plan&.mark_as_failed!
  
  # Return appropriate error response
  respond_to do |format|
    format.json do
      error_dto = DTOs::ErrorResponseDTO.single_error('Failed to initiate plan generation')
      render json: error_dto.serialize, status: :unprocessable_content
    end
    format.turbo_stream { render :create, status: :unprocessable_content }
  end
end
```

**User Preferences Check:**
```ruby
unless current_user.user_preference
  error_dto = DTOs::ErrorResponseDTO.single_error(
    'Cannot generate plan without user preferences. Please set your preferences first.'
  )
  render json: error_dto.serialize, status: :unprocessable_content
  return
end
```

### Logging:
- **Info Level:** Successful plan creation initiation
- **Warn Level:** Missing preferences
- **Error Level:** Exceptions, database errors, job queue failures
- Include controller action, user ID, trip ID in log context

## 8. Performance Considerations

### Database Queries:

**User Preferences Check:**
- Single query via `current_user.user_preference` (has_one association)
- Uses unique index on `user_id` for fast lookup

**Trip Lookup:**
- Uses `current_user.trips.find` which leverages existing indexes:
  - `index_trips_on_user_id_and_destination`
  - `index_trips_on_user_id_and_start_date`

### Background Job Queue:
- Uses Rails SolidQueue (configured in `config/queue.yml`)
- Job is queued asynchronously, doesn't block request
- Job processing happens in separate worker process

### Potential Bottlenecks:
1. **Background Job Queue:** Monitor queue depth; may need multiple workers in production
2. **OpenRouter API:** External API call in background job (not blocking request)

### Optimization Strategies:
- **Caching:** For frequently accessed user preferences, consider caching (though current query is fast)

## 9. Implementation Steps

### Step 1: Create Background Job
Create `app/jobs/generated_plan_generation_job.rb`:
- Inherit from `ApplicationJob`
- Accept `generated_plan_id` and `user_id` as parameters
- Load generated plan and update status to 'generating'
- Call `GeneratedPlans::Generate` service
- Handle service result and update plan status accordingly

### Step 2: Update Controller
Update `app/controllers/trips/generated_plans_controller.rb`:
- Parse request params using `Commands::GeneratedPlanCreateCommand.from_params`
- Validate command (return 422 if invalid)
- Check user preferences exist (return 422 if missing)
- Create generated plan with 'pending' status
- Queue background job `GeneratedPlanGenerationJob.perform_later`
- Return 202 Accepted with DTO and message
- Update error handling to use appropriate status codes

### Step 3: Update Response Format
Ensure JSON response includes `message` field:
- Add message to JSON response: `"Plan generation initiated. Please check back shortly."`
- Keep existing Turbo Stream response unchanged

### Step 4: Error Handling Refinement
- Ensure all error paths return correct status codes (404, 422, 500)
- Use `ApplicationController` error handlers where appropriate
- Add specific error handling for preferences check

### Step 5: Testing Considerations
- Test authentication requirement
- Test trip authorization (404 for non-existent or other user's trip)
- Test missing preferences (422)
- Test successful creation (202 with correct response)
- Test background job queuing
- Test Turbo Stream response format

### Step 6: Run Code Quality Checks
- Run `bundle exec rubocop -A` to fix style issues
- Fix any outstanding RuboCop offenses
- Ensure Sorbet type annotations are correct (if using strict typing)

### Step 7: Documentation Updates
- Ensure API documentation reflects actual implementation
- Update any controller comments with correct behavior

