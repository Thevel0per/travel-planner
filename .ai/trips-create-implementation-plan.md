# API Endpoint Implementation Plan: Create Trip

## 1. Endpoint Overview

The Create Trip endpoint allows authenticated users to create new travel trip records in the system. The endpoint accepts trip details including name, destination, dates, and number of travelers. It performs validation, associates the trip with the authenticated user, and returns the created trip resource in JSON format. This is a standard RESTful POST endpoint that creates a new resource in the `trips` table.

The endpoint requires authentication via Devise session, and enforces business rule validations including date range validation and positive integer constraints.

## 2. Request Details

- **HTTP Method:** `POST`
- **URL Structure:** `/trips`
- **Authentication:** Required (Devise session-based authentication)
- **Content-Type:** `application/json`

### Parameters

All parameters are provided in the request body under the `trip` key:

**Required Parameters:**
- `name` (String, max 255 characters): The name/title of the trip
- `destination` (String, max 255 characters): The destination location
- `start_date` (String, ISO 8601 date format: YYYY-MM-DD): Trip start date
- `end_date` (String, ISO 8601 date format: YYYY-MM-DD): Trip end date

**Optional Parameters:**
- `number_of_people` (Integer, default: 1, minimum: 1): Number of travelers

### Request Body Structure

The request body must be JSON with the following structure:
```json
{
  "trip": {
    "name": "Summer Vacation 2025",
    "destination": "Paris, France",
    "start_date": "2025-07-15",
    "end_date": "2025-07-22",
    "number_of_people": 2
  }
}
```

The `trip` key is required as per Rails conventions and the API specification. The endpoint should handle both nested (`{ "trip": { ... } }`) and flat parameter formats, but prefer the nested format for consistency.

## 3. Used Types

### Command Models

**`Commands::TripCreateCommand`**
- Purpose: Validates and transforms incoming request parameters
- Location: `app/types/commands/trip_create_command.rb`
- Key Features:
  - Parses request parameters from `params[:trip]` or flat `params`
  - Validates parameter presence and formats
  - Converts ISO 8601 date strings to `Date` objects via `to_model_attributes`
  - Provides default value for `number_of_people` (1)
- Usage: Instantiate via `TripCreateCommand.from_params(params)`, then call `to_model_attributes` to get attributes hash for model creation

### Data Transfer Objects (DTOs)

**`DTOs::TripDTO`**
- Purpose: Represents trip data in API responses
- Location: `app/types/dtos/trip_dto.rb`
- Key Features:
  - Immutable struct using Sorbet type system
  - Formats dates and timestamps as ISO 8601 strings
  - Includes `from_model` class method to convert ActiveRecord model to DTO
- Usage: Call `TripDTO.from_model(trip)` after successful creation, then serialize for JSON response

**`DTOs::ErrorResponseDTO`**
- Purpose: Standardized error response format
- Location: `app/types/dtos/error_response_dto.rb`
- Key Features:
  - Supports both single error messages and field-specific validation errors
  - Provides `from_model_errors` method to convert ActiveRecord validation errors
  - Formats errors as hash: `{ "field_name": ["error message 1", "error message 2"] }`
- Usage: Call `ErrorResponseDTO.from_model_errors(trip)` for model validation errors, or `ErrorResponseDTO.validation_errors(errors_hash)` for custom errors

## 4. Response Details

### Success Response (201 Created)

When a trip is successfully created, the endpoint returns:
- **Status Code:** `201 Created`
- **Content-Type:** `application/json`
- **Response Body:**
```json
{
  "trip": {
    "id": 1,
    "name": "Summer Vacation 2025",
    "destination": "Paris, France",
    "start_date": "2025-07-15",
    "end_date": "2025-07-22",
    "number_of_people": 2,
    "created_at": "2025-10-19T12:00:00Z",
    "updated_at": "2025-10-19T12:00:00Z"
  }
}
```

The response wraps the trip object in a `trip` key for consistency with Rails conventions. All date fields use ISO 8601 format (dates as YYYY-MM-DD, timestamps as YYYY-MM-DDTHH:MM:SSZ in UTC).

### Error Responses

**422 Unprocessable Entity - Validation Errors**

When validation fails, returns:
- **Status Code:** `422 Unprocessable Entity`
- **Response Body:**
```json
{
  "errors": {
    "name": ["can't be blank"],
    "end_date": ["must be after start date"],
    "number_of_people": ["must be greater than 0"]
  }
}
```

The errors object contains field names as keys and arrays of error messages as values. This format matches Rails validation error structure and allows clients to display field-specific error messages.

**401 Unauthorized**

When user is not authenticated:
- **Status Code:** `401 Unauthorized`
- **Response Body:** Determined by Devise (typically redirect for HTML, error message for JSON)

**400 Bad Request**

When request body is malformed or missing required top-level `trip` key:
- **Status Code:** `400 Bad Request`
- **Response Body:**
```json
{
  "error": "Missing required parameters"
}
```

**500 Internal Server Error**

When unexpected server errors occur:
- **Status Code:** `500 Internal Server Error`
- **Response Body:**
```json
{
  "error": "An unexpected error occurred"
}
```

## 5. Data Flow

### Step-by-Step Flow

1. **Request Reception**
   - Rails router matches `POST /trips` to `TripsController#create`
   - `before_action :authenticate_user!` ensures user is authenticated
   - If not authenticated, Devise redirects or returns 401

2. **Parameter Extraction and Transformation**
   - Controller receives request parameters
   - `TripCreateCommand.from_params(params)` is called to:
     - Extract parameters from `params[:trip]` or fallback to flat `params`
     - Instantiate command object with validated parameter structure
     - Command object validates parameter presence and types at command level

3. **Model Creation**
   - Controller calls `to_model_attributes` on command object to get attributes hash
   - Attributes hash includes:
     - All trip attributes (name, destination, etc.)
     - `start_date` and `end_date` converted from ISO 8601 strings to `Date` objects
     - `user_id` set to `current_user.id` (from authenticated session)
   - Controller creates new `Trip` record using `Trip.new(attributes)` or `current_user.trips.build(attributes)`
   - Model validations execute:
     - Presence validations for required fields
     - Length validations for string fields
     - Numericality validation for `number_of_people`
     - Custom `end_date_after_start_date` validation

4. **Persistence and Response**
   - If model is valid: `trip.save` persists to database
   - On success: Transform saved model to DTO via `TripDTO.from_model(trip)`
   - Serialize DTO to JSON with `trip` key wrapper
   - Return 201 Created status with JSON response
   - On validation failure: Convert model errors to `ErrorResponseDTO` via `ErrorResponseDTO.from_model_errors(trip)`
   - Return 422 status with validation errors JSON

5. **Error Handling**
   - Database errors (e.g., foreign key violations): Caught by `rescue_from StandardError` in ApplicationController
   - Parameter errors: Caught by `rescue_from ActionController::ParameterMissing`
   - All errors logged via `Rails.logger` with appropriate severity levels

### Database Interactions

- **Insert Operation:** Single `INSERT` statement to `trips` table
- **Foreign Key:** `user_id` automatically set from `current_user.id`
- **Timestamps:** `created_at` and `updated_at` automatically set by Rails
- **No Cascading:** Creation does not trigger cascading operations (unlike deletion)
- **Indexes:** Insert uses `user_id` index for foreign key validation

### Service Layer Consideration

For this endpoint, a dedicated service object is **not necessary** because:
- Business logic is straightforward (parameter validation + model creation)
- No external API calls or complex operations
- No need for transaction management beyond standard model save
- Model validations cover all business rules

However, if the application evolves to require:
- Pre-creation hooks (e.g., sending notifications)
- Complex validation across multiple models
- Integration with external services
- Background job queuing

Do not keep the creation logic in the controller encapsulate it under models/trips/create

## 6. Security Considerations

### Authentication

- **Requirement:** All requests must be authenticated via Devise session
- **Implementation:** `before_action :authenticate_user!` in controller
- **Mechanism:** Session-based authentication using encrypted cookies
- **Enforcement:** Devise automatically handles unauthenticated requests (redirect for HTML, 401 for JSON if configured)

### Authorization

- **User Association:** Trips are automatically scoped to authenticated user
- **Implementation:** Set `user_id` from `current_user.id` during creation
- **No User Override:** Request should not accept or process `user_id` parameter (even if provided, it should be ignored and set from session)
- **Enforcement:** Rails foreign key constraint ensures `user_id` references valid user, but application-level setting prevents privilege escalation

### Input Validation

**Parameter Whitelisting:**
- Only accept expected parameters: `name`, `destination`, `start_date`, `end_date`, `number_of_people`
- Ignore any additional parameters (Rails strong parameters)
- Reject `user_id` if provided in request (security: prevent user spoofing)

## 7. Error Handling

### Validation Errors (422 Unprocessable Entity)

**Triggered When:**
- Missing required fields (name, destination, start_date, end_date)
- Invalid date formats (non-parseable strings)
- Date logic violations (end_date <= start_date)
- Invalid `number_of_people` (non-integer, zero, or negative)
- String length violations (name or destination > 255 characters)

**Error Format:**
```json
{
  "errors": {
    "field_name": ["error message 1", "error message 2"]
  }
}
```

**Implementation:**
- Use `ErrorResponseDTO.from_model_errors(trip)` to convert ActiveRecord errors
- Status code: `422` (Rails convention for validation errors)
- Do not log validation errors as warnings (they are expected user input issues)

### Authentication Errors (401 Unauthorized)

**Triggered When:**
- User session expired or invalid
- User not logged in
- Devise authentication fails

**Handling:**
- Devise handles automatically via `authenticate_user!` before_action
- For JSON requests, should return 401 with error message
- May need to configure Devise to return JSON error instead of redirect

### Bad Request (400 Bad Request)

**Triggered When:**
- Missing `trip` key in request body
- Malformed JSON in request body
- Invalid parameter types (e.g., number_of_people as string when integer expected at command level)

**Error Format:**
```json
{
  "error": "Missing required parameters"
}
```

**Implementation:**
- Use `rescue_from ActionController::ParameterMissing` in ApplicationController
- Or check for presence of `params[:trip]` in controller and return 400 if missing
- Status code: `400`

### Not Found (404 Not Found)

**Not Applicable:** Creation endpoint does not reference existing resources, so 404 is not used for this endpoint.

### Server Errors (500 Internal Server Error)

**Triggered When:**
- Database connection failures
- Unexpected exceptions during save operation
- Foreign key constraint violations (though should be prevented by setting user_id correctly)

**Error Format:**
```json
{
  "error": "An unexpected error occurred"
}
```

**Implementation:**
- Use `rescue_from StandardError` in ApplicationController
- Log full exception details to `Rails.logger.error`
- Return generic error message to client (do not expose internal details)
- Status code: `500`

### Error Logging Strategy

- **Validation Errors:** Do not log (expected user input issues)
- **Authentication Errors:** Log as warning with user context
- **Bad Request:** Log as warning with request details
- **Server Errors:** Log as error with full exception and stack trace
- **All Errors:** Include controller action, user ID (if available), and timestamp in logs

## 8. Performance Considerations

### Database Performance

**Insert Operation:**
- Single-row INSERT is fast (typically < 10ms for indexed tables)
- Foreign key index on `user_id` ensures fast validation
- No complex queries or joins required

**Optimization Opportunities:**
- No N+1 queries (single insert operation)
- No eager loading needed (no associations loaded)
- Consider database connection pooling for high concurrency

### Response Performance

**DTO Transformation:**
- Simple model-to-DTO conversion (minimal overhead)
- No complex serialization logic
- JSON serialization is fast with Rails

**Payload Size:**
- Small response payload (< 500 bytes typical)
- No pagination or large data sets

### Scalability Considerations

**Concurrent Requests:**
- Rails handles concurrent requests via multi-threaded or multi-process servers (Puma)
- Database connection pool limits concurrent database operations
- No shared state or locking required for creation

**Rate Limiting:**
- Consider implementing rate limits to prevent abuse
- Database writes are more expensive than reads, so limiting creation rate protects database

**Future Optimizations:**
- If trip creation becomes bottleneck, consider:
  - Async creation via background jobs (but would require 202 Accepted response)
  - Batch creation endpoints (not in scope for MVP)
  - Database write replicas for scaling (advanced)

## 9. Implementation Steps

### Step 1: Controller Action Implementation

1. Add `create` action to `TripsController`
2. Implement `before_action :authenticate_user!` if not already present (should be inherited or set at controller level)
3. Extract parameters using `TripCreateCommand.from_params(params)`
4. Convert command to model attributes via `to_model_attributes`
5. Set `user_id` from `current_user.id` in attributes hash
6. Create new `Trip` instance with attributes
7. Attempt to save the trip
8. On success: Return 201 with `TripDTO.from_model(trip)` serialized as JSON
9. On validation failure: Return 422 with `ErrorResponseDTO.from_model_errors(trip)` serialized as JSON

### Step 2: Error Handling Integration

1. Ensure `ApplicationController` has `rescue_from` handlers for:
   - `StandardError` → 500 Internal Server Error
   - `ActionController::ParameterMissing` → 400 Bad Request
   - `ActiveRecord::RecordInvalid` → 422 (if needed, though manual handling preferred)
2. Verify error handlers return JSON format for JSON requests
3. Test that authentication errors return 401 for JSON requests (may need Devise configuration)

### Step 3: Parameter Validation

1. Verify `TripCreateCommand` handles:
   - Nested params (`params[:trip]`)
   - Flat params fallback
   - Missing parameter scenarios
   - Invalid date format handling (Date.parse errors)
2. Add command-level validations if needed for early parameter validation
3. Ensure date parsing errors are caught and converted to appropriate error responses

### Step 4: Response Formatting

1. Verify `TripDTO.from_model` correctly formats:
   - Dates as ISO 8601 (YYYY-MM-DD)
   - Timestamps as ISO 8601 with timezone (YYYY-MM-DDTHH:MM:SSZ)
   - All required fields from trip model
2. Ensure response wrapper includes `trip` key: `{ "trip": { ... } }`
3. Verify status code is `201 Created` on success

### Step 5: Testing

1. **Unit Tests:**
   - Test `TripCreateCommand.from_params` with various parameter formats
   - Test `TripCreateCommand.to_model_attributes` date conversion
   - Test model validations independently

2. **Controller Tests (RSpec):**
   - Test successful creation with valid parameters
   - Test 201 response status and correct JSON structure
   - Test validation errors return 422 with correct error format
   - Test missing `trip` key returns 400
   - Test authentication required (401 when not logged in)
   - Test `user_id` is set from `current_user` (not from params)
   - Test date range validation (end_date <= start_date)
   - Test invalid date formats are handled gracefully

3. **Integration Tests:**
   - Test full request/response cycle
   - Test database persistence
   - Test foreign key constraint (user_id must exist)

### Step 6: Documentation and Code Review

1. Add inline comments to controller action explaining flow
2. Document any deviations from standard Rails patterns
3. Verify code follows Rails conventions and project style guide
4. Run Rubocop and fix any style violations
5. Ensure Sorbet type annotations are correct (if using typed: strict)

### Step 7: Route Verification

1. Verify route `POST /trips` is defined in `config/routes.rb`
2. Ensure route maps to `TripsController#create`
3. Verify no route conflicts

### Step 8: Security Verification

1. Verify `user_id` cannot be overridden via request parameters
2. Test that unauthenticated requests are properly rejected
3. Verify CSRF protection is appropriately configured for JSON requests
4. Test parameter whitelisting (extra parameters ignored)
5. Verify date parsing does not allow code injection

### Step 10: Deployment Readiness

1. Verify all tests pass
2. Check error logging in development environment
3. Verify error responses match API specification exactly
4. Ensure no sensitive information leaked in error messages
5. Confirm database migrations are applied (trips table exists with correct schema)

