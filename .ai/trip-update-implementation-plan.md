# API Endpoint Implementation Plan: Update Trip (PUT/PATCH /trips/:id)

## 1. Endpoint Overview

This endpoint updates an existing trip for the authenticated user. The endpoint supports partial updates (all fields are optional), allowing users to modify one or more trip attributes without providing all fields. The endpoint supports both HTML and JSON response formats and ensures that users can only update their own trips through proper authorization scoping.

**Purpose:** Allow users to modify trip details such as name, destination, dates, and number of people after initial creation.

**Authentication:** Required (Devise session-based authentication)

**HTTP Methods Supported:** `PUT` and `PATCH` (both map to the same `update` action in Rails)

## 2. Request Details

- **HTTP Method:** `PUT` or `PATCH`
- **URL Structure:** `/trips/:id`
- **Parameters:**
  - **Required:**
    - `id` (route parameter) - Integer ID of the trip to update
  - **Optional (all fields in request body):**
    - `name` - String, maximum 255 characters
    - `destination` - String, maximum 255 characters
    - `start_date` - String in ISO 8601 date format (YYYY-MM-DD)
    - `end_date` - String in ISO 8601 date format (YYYY-MM-DD)
    - `number_of_people` - Integer, must be greater than 0
- **Request Body Structure:**
```json
{
  "trip": {
    "name": "Updated Summer Vacation 2025",
    "destination": "Paris, France",
    "start_date": "2025-07-16",
    "end_date": "2025-07-23",
    "number_of_people": 3
  }
}
```
  - **Alternative Format (flat):** Parameters can also be provided directly without the "trip" wrapper (handled by `TripUpdateCommand.from_params`)
- **Content-Type:** `application/json` (for JSON requests) or `application/x-www-form-urlencoded` (for HTML form submissions)
- **Accept:** `application/json` or `text/html` (via Accept header or format parameter)

## 3. Used Types

### DTOs (Data Transfer Objects)
- **TripDTO** - Main response DTO with `from_model` factory method (does not include nested associations for update response)
  - Returns basic trip attributes without notes or generated_plans counts
- **ErrorResponseDTO** - For validation errors (422) and error responses (404, 500)
  - Uses `from_model_errors` for validation errors
  - Uses `single_error` for general errors

### Command Models
- **TripUpdateCommand** - Command object for parsing and validating update parameters
  - All fields are optional (supports partial updates)
  - Provides `from_params` to parse request parameters (handles both nested and flat formats)
  - Provides `to_model_attributes` to convert to hash for ActiveRecord update
  - Handles date string parsing to Date objects

### Enums
- None required for this endpoint

## 4. Response Details

### Success Response (200 OK)

**JSON Format:**
```json
{
  "trip": {
    "id": 1,
    "name": "Updated Summer Vacation 2025",
    "destination": "Paris, France",
    "start_date": "2025-07-16",
    "end_date": "2025-07-23",
    "number_of_people": 3,
    "created_at": "2025-10-19T12:00:00Z",
    "updated_at": "2025-10-19T14:00:00Z"
  }
}
```

**HTML Format:**
- Redirects to trip show page (`trip_path(@trip)`) with success flash message
- Flash message: `flash[:notice] = 'Trip updated successfully'`

### Error Responses

**401 Unauthorized (Not Authenticated):**
- Handled automatically by Devise `before_action :authenticate_user!`
- JSON: Returns Devise's standard unauthorized response
- HTML: Redirects to sign-in page

**404 Not Found:**
- Trip doesn't exist or doesn't belong to the authenticated user
- Handled by `ApplicationController#handle_not_found` rescue handler
```json
{
  "error": "Resource not found"
}
```

**422 Unprocessable Content (Validation Errors):**
- Model validations fail (e.g., end_date <= start_date, invalid dates, etc.)
- Handled by checking `trip.errors.any?` after update attempt
```json
{
  "errors": {
    "end_date": ["must be after start date"],
    "name": ["can't be blank"]
  }
}
```

**400 Bad Request:**
- Invalid date format in start_date or end_date (causes Date.parse to raise ArgumentError)
- Missing or empty request body (no fields provided for update)
- Handled by catching ArgumentError or validating at least one field is provided
```json
{
  "error": "Invalid date format. Expected YYYY-MM-DD"
}
```

**500 Internal Server Error:**
- Unexpected server-side errors (database failures, etc.)
- Handled by `ApplicationController#handle_server_error` (if implemented)
```json
{
  "error": "An unexpected error occurred"
}
```

## 5. Data Flow

### Request Processing Flow:

```
1. HTTP Request (PUT/PATCH /trips/:id with JSON body)
   ↓
2. Rails Router → TripsController#update
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. Find trip scoped to current_user (prevents unauthorized access)
   - current_user.trips.find(params[:id])
   ↓
5. Parse request parameters using TripUpdateCommand
   - command = Commands::TripUpdateCommand.from_params(params)
   ↓
6. Convert command to model attributes
   - attributes = command.to_model_attributes
   ↓
7. Update trip with attributes
   - @trip.update(attributes)
   ↓
8. Check if update succeeded:
   - If successful: Transform Trip model → TripDTO
   - If validation failed: Transform errors → ErrorResponseDTO
   ↓
9. Respond based on format:
   - JSON: render json: { trip: dto.serialize }, status: :ok (or 422)
   - HTML: redirect with flash message (or re-render with errors)
```

### Database Queries:

**Primary Query (find trip):**
```ruby
current_user.trips.find(params[:id])
```

**Expected SQL:**
```sql
SELECT "trips".* FROM "trips" 
WHERE "trips"."user_id" = ? AND "trips"."id" = ? 
LIMIT 1
```

**Update Query:**
```ruby
@trip.update(attributes)
```

**Expected SQL:**
```sql
UPDATE "trips" 
SET "name" = ?, "destination" = ?, "start_date" = ?, "end_date" = ?, "number_of_people" = ?, "updated_at" = ? 
WHERE "trips"."id" = ?
```

### External Service Interactions:
None (pure database operation)

## 6. Security Considerations

### Authentication:
- **Devise Integration:** Use `before_action :authenticate_user!` to ensure user is signed in
- **Session-based:** Relies on Devise session cookie for authentication
- **Automatic handling:** Devise handles unauthenticated requests automatically (redirects HTML, returns 401 for JSON)

### Authorization:
- **User Scoping:** CRITICAL - Always scope to `current_user.trips.find(params[:id])` to prevent unauthorized access to other users' trips
- **Automatic protection:** Using `current_user.trips` ensures that ActiveRecord raises `ActiveRecord::RecordNotFound` if the trip belongs to another user
- **No shared trips:** Current design has no trip sharing functionality, so strict user ownership applies
- **Route parameter validation:** Rails automatically validates `:id` is present in route, but doesn't validate format (handled by ActiveRecord when converting to integer)

### Data Validation:
- **ID Format:** ActiveRecord's `find` method handles invalid ID formats gracefully (raises `ActiveRecord::RecordNotFound`)
- **SQL Injection Protection:** ActiveRecord parameter binding prevents SQL injection
- **XSS Protection:** Rails automatically escapes JSON output, and HTML views use ERB escaping
- **Mass Assignment Protection:** Using `TripUpdateCommand.to_model_attributes` ensures only allowed fields are updated
- **User ID Protection:** Never allow `user_id` to be updated - ensure it's not in the attributes hash (already protected by scoping to `current_user.trips`)

### Potential Security Threats:

1. **Unauthorized Update Attempts:**
   - **Threat:** User attempting to update another user's trip by guessing IDs
   - **Mitigation:** Using `current_user.trips.find` ensures trips are scoped to the authenticated user. Attempting to update another user's trip results in 404 (not revealing trip existence).

2. **ID Enumeration:**
   - **Threat:** Malicious user enumerating trip IDs
   - **Mitigation:** 404 responses don't reveal whether trip exists or belongs to another user. Rate limiting should be implemented at application/infrastructure level.

3. **Mass Assignment:**
   - **Threat:** User attempting to modify protected fields (e.g., user_id, created_at)
   - **Mitigation:** `TripUpdateCommand.to_model_attributes` only includes explicitly allowed fields. Never include `user_id` in update attributes (trip already scoped to user).

4. **Date Format Injection:**
   - **Threat:** Invalid date formats could cause errors
   - **Mitigation:** Catch `ArgumentError` from `Date.parse` and return 400 Bad Request with clear error message.

5. **CSRF:**
   - **Protection:** Rails CSRF protection handles HTML form submissions. JSON API requests from authenticated sessions should verify CSRF token for state-changing operations (Rails handles this automatically for forms).

6. **Empty Update Requests:**
   - **Threat:** Request with no fields to update (no-op but wastes resources)
   - **Mitigation:** Validate that at least one field is provided (optional check, can return 400 or silently succeed).

## 7. Error Handling

### Error Scenarios and Handling:

| Scenario | HTTP Status | Handler | Message |
|----------|-------------|---------|---------|
| User not authenticated | 401 | Devise | Standard Devise unauthorized response |
| Trip ID missing/invalid format | 404 | `handle_not_found` | "Resource not found" |
| Trip not found | 404 | `handle_not_found` | "Resource not found" |
| Trip belongs to different user | 404 | `handle_not_found` | "Resource not found" |
| Invalid date format | 400 | Manual rescue | "Invalid date format. Expected YYYY-MM-DD" |
| Empty update (no fields provided) | 400 | Manual validation | "At least one field must be provided" (optional) |
| end_date <= start_date | 422 | Model validation | "end_date must be after start date" |
| name blank (if provided) | 422 | Model validation | "name can't be blank" |
| destination blank (if provided) | 422 | Model validation | "destination can't be blank" |
| number_of_people <= 0 (if provided) | 422 | Model validation | "number_of_people must be greater than 0" |
| String length violations | 422 | Model validation | Field-specific error messages |
| Database connection error | 500 | `handle_server_error` | "An unexpected error occurred" |
| Unexpected exception | 500 | `handle_server_error` | "An unexpected error occurred" |

### Date Parsing Error Handling:

The `TripUpdateCommand.to_model_attributes` method uses `Date.parse(start_date)` and `Date.parse(end_date)`, which can raise `ArgumentError` for invalid date formats.

**Implementation:**
```ruby
# In controller, wrap date parsing in rescue block
begin
  attributes = command.to_model_attributes
rescue ArgumentError => e
  error_dto = DTOs::ErrorResponseDTO.single_error('Invalid date format. Expected YYYY-MM-DD')
  render json: error_dto.serialize, status: :bad_request
  return
end
```

**Alternative (better):** Handle in command object itself and return validation error, but simpler to catch in controller for now.

### Validation Error Handling:

Validation errors are handled by ActiveRecord validations on the Trip model:
- Check `@trip.errors.any?` after `@trip.update(attributes)`
- Use `DTOs::ErrorResponseDTO.from_model_errors(@trip)` to format errors
- Return 422 status code

### Error Logging:

- **404 Errors:** Logged at WARN level via `ApplicationController#handle_not_found`
  - Includes controller, action, and exception message
- **422 Errors (Validation):** Do NOT log as warnings (expected user input issues)
  - Only log at DEBUG level if needed for debugging
- **400 Errors (Bad Request):** Logged at WARN level
  - Invalid date formats or empty requests indicate client errors
- **500 Errors:** Logged at ERROR level via `ApplicationController#handle_server_error`
  - Includes full exception message and backtrace
- **Rails Logger:** All errors logged to `log/development.log` (development) or application logs (production)

### Error Response Format:

**Validation Errors (422):**
```json
{
  "errors": {
    "end_date": ["must be after start date"],
    "name": ["can't be blank"]
  }
}
```

**Single Error (400, 404, 500):**
```json
{
  "error": "Invalid date format. Expected YYYY-MM-DD"
}
```

For HTML requests, errors are displayed via flash messages and redirects or form re-rendering.

## 8. Performance Considerations

### Optimization Strategies:

1. **Database Indexing:**
   - `trips.id` is automatically indexed (primary key)
   - `trips.user_id` has index for foreign key
   - These indexes ensure fast lookups even with large datasets

2. **Update Efficiency:**
   - Only update fields that are provided (partial updates)
   - ActiveRecord's `update` method only includes changed fields in SQL UPDATE
   - No unnecessary field updates if value hasn't changed

3. **Validation Performance:**
   - Model validations run before database write, preventing unnecessary database operations
   - Validations are lightweight (presence checks, date comparisons)

4. **Response Size:**
   - Update response is minimal (just the updated trip DTO)
   - No nested associations included in response (unlike show endpoint)
   - Fast JSON serialization

### Potential Bottlenecks:

- **Date Parsing:** String to Date parsing is minimal overhead, but could add up with many concurrent requests
  - **Mitigation:** Usually negligible, but monitor if needed
- **Validation Checks:** Complex validations (e.g., end_date > start_date) require date comparisons
  - **Mitigation:** Lightweight operations, no performance concern
- **Database Write:** UPDATE query execution time
  - **Mitigation:** Ensure proper indexing, usually very fast for single record updates

### No Performance Issues Expected:

- Single record update operation is very fast
- No N+1 queries (not loading associations)
- Minimal response payload
- No external service calls

## 9. Implementation Steps

1. **Add `update` action to `TripsController`:**
   - Add method signature with `sig { void }` for Sorbet typing
   - Use `current_user.trips.find(params[:id])` to find and authorize trip
   - Handle `ActiveRecord::RecordNotFound` (automatically handled by `rescue_from` in ApplicationController)
   - Store result in `@trip` instance variable

2. **Parse Request Parameters:**
   - Use `Commands::TripUpdateCommand.from_params(params.permit!.to_h)` to parse request body
   - Command handles both nested (`params[:trip]`) and flat parameter formats
   - All fields are optional (partial updates supported)

3. **Convert Command to Model Attributes:**
   - Call `command.to_model_attributes` to get hash of attributes to update
   - This method handles date string parsing and only includes provided fields
   - Handle `ArgumentError` from invalid date formats (return 400 Bad Request)

4. **Validate Empty Update (Optional):**
   - Check if attributes hash is empty (no fields provided)
   - If empty, return 400 Bad Request with error message
   - Alternatively, allow empty updates as no-op (return 200 with unchanged trip)

5. **Update Trip:**
   - Call `@trip.update(attributes)` to apply changes
   - ActiveRecord will run model validations automatically
   - Check `@trip.errors.any?` to determine if update succeeded

6. **Handle Success Response:**
   - Transform updated trip to DTO: `DTOs::TripDTO.from_model(@trip)`
   - For JSON: `render json: { trip: dto.serialize }, status: :ok`
   - For HTML: `redirect_to trip_path(@trip), notice: 'Trip updated successfully'`

7. **Handle Validation Errors:**
   - If `@trip.errors.any?` is true, create error DTO: `DTOs::ErrorResponseDTO.from_model_errors(@trip)`
   - For JSON: `render json: error_dto.serialize, status: :unprocessable_content`
   - For HTML: Re-render edit form with errors (or redirect with flash alerts)

8. **Add Route Verification:**
   - Verify route is defined in `config/routes.rb` (should already exist: `resources :trips`)
   - Route should map to `trips#update` with `:id` parameter
   - Both PUT and PATCH methods should route to update action

9. **Testing Considerations:**
   - Test successful partial update (update only one field)
   - Test successful full update (update all fields)
   - Test successful empty update (no-op, if allowed)
   - Test 404 when trip doesn't exist
   - Test 404 when trip belongs to different user (authorization)
   - Test 401 when user not authenticated
   - Test 422 validation errors (end_date <= start_date, blank fields, etc.)
   - Test 400 invalid date formats
   - Test 400 empty request body (if validation added)
   - Test JSON response format matches API specification
   - Test HTML response redirects correctly
   - Test that user_id cannot be changed (security)
   - Test that created_at and updated_at are handled correctly

10. **Error Handling Verification:**
    - Verify `rescue_from ActiveRecord::RecordNotFound` in ApplicationController handles 404s
    - Verify date parsing errors return 400 with clear message
    - Verify validation errors return 422 with proper error structure
    - Verify error response format matches `ErrorResponseDTO` structure
    - Verify logging occurs for errors (except validation errors)

11. **Security Verification:**
    - Verify users can only update their own trips
    - Verify user_id cannot be modified via request
    - Verify proper authentication is required

### Notes on Implementation:

- The `rescue_from ActiveRecord::RecordNotFound` in `ApplicationController` will automatically catch any `RecordNotFound` exception raised by `find`
- Using `current_user.trips` ensures proper authorization - if the trip belongs to another user, ActiveRecord will raise `RecordNotFound` when it can't find the trip in the scoped collection
- The `TripUpdateCommand.to_model_attributes` method only includes fields that are present (not nil), enabling partial updates
- Date parsing errors must be caught explicitly since `Date.parse` raises `ArgumentError` for invalid formats
- The empty attributes check is optional - some APIs allow no-op updates, others require at least one field
- Follow the existing pattern from `create` action for consistency (error handling, response formats, etc.)
- For HTML responses, consider whether to re-render the edit form with errors or redirect (redirect is simpler and follows Rails conventions)

