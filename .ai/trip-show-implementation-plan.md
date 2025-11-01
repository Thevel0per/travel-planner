# API Endpoint Implementation Plan: Get Trip (GET /trips/:id)

## 1. Endpoint Overview

This endpoint retrieves a specific trip with its associated notes and generated plans for the authenticated user. The endpoint supports both HTML and JSON response formats and ensures that users can only access their own trips through proper authorization scoping.

**Purpose:** Provide detailed trip information including nested notes and generated plans for viewing/editing trip details.

**Authentication:** Required (Devise session-based authentication)

## 2. Request Details

- **HTTP Method:** `GET`
- **URL Structure:** `/trips/:id`
- **Parameters:**
  - **Required:**
    - `id` (route parameter) - Integer ID of the trip to retrieve
  - **Optional:** None
- **Request Body:** Not applicable (GET request)
- **Content-Type:** Not required for GET requests
- **Accept:** `application/json` or `text/html` (via Accept header or format parameter)

## 3. Used Types

### DTOs (Data Transfer Objects)
- **TripDTO** - Main response DTO with `from_model_with_associations` factory method
  - Includes nested `notes` array (NoteDTO instances)
  - Includes nested `generated_plans` array (GeneratedPlanDTO instances)
- **NoteDTO** - DTO for nested notes in the response
- **GeneratedPlanDTO** - DTO for nested generated plans in the response
- **ErrorResponseDTO** - For error responses (404, 500)

### Command Models
- None required (GET endpoint has no request body)

### Enums
- None required for this endpoint

## 4. Response Details

### Success Response (200 OK)

**JSON Format:**
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
    "updated_at": "2025-10-19T12:00:00Z",
    "notes": [
      {
        "id": 1,
        "trip_id": 1,
        "content": "Visit Eiffel Tower",
        "created_at": "2025-10-19T12:00:00Z",
        "updated_at": "2025-10-19T12:00:00Z"
      }
    ],
    "generated_plans": [
      {
        "id": 1,
        "trip_id": 1,
        "status": "completed",
        "rating": 8,
        "created_at": "2025-10-19T12:00:00Z",
        "updated_at": "2025-10-19T12:00:00Z"
      }
    ]
  }
}
```

**HTML Format:**
- Renders `trips/show.html.erb` view template
- Sets `@trip` instance variable for the view

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
  "errors": [
    {
      "field": "server",
      "message": "Resource not found"
    }
  ]
}
```

**500 Internal Server Error:**
- Unexpected server-side errors
- Handled by `ApplicationController#handle_server_error` (if implemented)
```json
{
  "errors": [
    {
      "field": "server",
      "message": "An unexpected error occurred"
    }
  ]
}
```

## 5. Data Flow

### Request Processing Flow:

```
1. HTTP Request (GET /trips/:id)
   ↓
2. Rails Router → TripsController#show
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. Find trip scoped to current_user (prevents unauthorized access)
   - current_user.trips.includes(:notes, :generated_plans).find(params[:id])
   ↓
5. Transform Trip model → TripDTO using from_model_with_associations
   - This automatically transforms nested notes → NoteDTO[]
   - This automatically transforms nested generated_plans → GeneratedPlanDTO[]
   ↓
6. Respond based on format:
   - JSON: render json: { trip: dto.serialize }, status: :ok
   - HTML: render :show with @trip instance variable
```

### Database Queries:

**Primary Query (with eager loading to prevent N+1):**
```ruby
current_user.trips
  .includes(:notes, :generated_plans)
  .find(params[:id])
```

**Expected SQL (optimized):**
```sql
-- Trip query
SELECT "trips".* FROM "trips" 
WHERE "trips"."user_id" = ? AND "trips"."id" = ? 
LIMIT 1

-- Notes query (eager loaded)
SELECT "notes".* FROM "notes" 
WHERE "notes"."trip_id" IN (?)

-- Generated plans query (eager loaded)
SELECT "generated_plans".* FROM "generated_plans" 
WHERE "generated_plans"."trip_id" IN (?)
```

**Alternative (if associations need ordering):**
```ruby
current_user.trips
  .includes(:notes, :generated_plans)
  .find(params[:id])

# Then in TripDTO.from_model_with_associations:
notes: trip.notes.order(created_at: :desc).map { |note| DTOs::NoteDTO.from_model(note) },
generated_plans: trip.generated_plans.order(created_at: :desc).map { |plan| DTOs::GeneratedPlanDTO.from_model(plan) }
```

### External Service Interactions:
None (pure database read operation)

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

### Potential Security Threats:

1. **Unauthorized Access Attempts:**
   - **Threat:** User attempting to access another user's trip by guessing IDs
   - **Mitigation:** Using `current_user.trips.find` ensures trips are scoped to the authenticated user. Attempting to access another user's trip results in 404 (not revealing trip existence).

2. **ID Enumeration:**
   - **Threat:** Malicious user enumerating trip IDs
   - **Mitigation:** 404 responses don't reveal whether trip exists or belongs to another user. Rate limiting should be implemented at application/infrastructure level.

3. **Mass Assignment:**
   - **Not applicable:** GET request has no request body

4. **CSRF:**
   - **Protection:** Rails CSRF protection handles HTML form submissions. JSON API requests from authenticated sessions are typically exempt, but should verify CSRF token for state-changing operations.

## 7. Error Handling

### Error Scenarios and Handling:

| Scenario | HTTP Status | Handler | Message |
|----------|-------------|---------|---------|
| User not authenticated | 401 | Devise | Standard Devise unauthorized response |
| Trip ID missing/invalid format | 404 | `handle_not_found` | "Resource not found" |
| Trip not found | 404 | `handle_not_found` | "Resource not found" |
| Trip belongs to different user | 404 | `handle_not_found` | "Resource not found" |
| Database connection error | 500 | `handle_server_error` | "An unexpected error occurred" |
| Unexpected exception | 500 | `handle_server_error` | "An unexpected error occurred" |

### Error Logging:

- **404 Errors:** Logged at WARN level via `ApplicationController#handle_not_found`
  - Includes controller, action, and exception message
- **500 Errors:** Logged at ERROR level via `ApplicationController#handle_server_error`
  - Includes full exception message and backtrace
- **Rails Logger:** All errors logged to `log/development.log` (development) or application logs (production)

### Error Response Format:

All errors follow the `ErrorResponseDTO` structure:
```json
{
  "errors": [
    {
      "field": "server",
      "message": "Resource not found"
    }
  ]
}
```

For HTML requests, errors are displayed via flash messages and redirects.

## 8. Performance Considerations

### Optimization Strategies:

1. **Eager Loading Associations:**
   - Use `.includes(:notes, :generated_plans)` to prevent N+1 queries
   - Ensures all associations are loaded in a single database round-trip

2. **Database Indexing:**
   - `trips.id` is automatically indexed (primary key)
   - `trips.user_id` has index for foreign key
   - `notes.trip_id` has index for foreign key
   - `generated_plans.trip_id` has index for foreign key
   - These indexes ensure fast lookups even with large datasets

3. **Association Ordering (Optional):**
   - If notes/generated_plans should be ordered (e.g., by created_at), consider:
     - Adding default scopes to Note and GeneratedPlan models
     - Or ordering in the DTO transformation (already loaded, no extra query)

4. **Caching (Future Consideration):**
   - Consider fragment caching for HTML views if trip data doesn't change frequently
   - For JSON API, consider HTTP caching headers (ETag, Last-Modified)

5. **Response Size:**
   - Trip with many notes/generated_plans could result in large JSON responses
   - Consider pagination for notes/plans if they exceed reasonable limits (not required for initial implementation)

### Potential Bottlenecks:

- **Large Associations:** If a trip has hundreds of notes or generated plans, the response could be large
  - **Mitigation:** Consider pagination or limiting associations for the show endpoint (future enhancement)
- **JSON Serialization:** Large nested structures may take time to serialize
  - **Mitigation:** Usually negligible, but monitor performance in production

## 9. Implementation Steps

1. **Add `show` action to `TripsController`:**
   - Add method signature with `sig { void }` for Sorbet typing
   - Use `current_user.trips.includes(:notes, :generated_plans).find(params[:id])` to find and authorize trip
   - Handle `ActiveRecord::RecordNotFound` (automatically handled by `rescue_from` in ApplicationController)
   - Store result in `@trip` instance variable for views

2. **Transform Trip to DTO:**
   - Use `DTOs::TripDTO.from_model_with_associations(@trip)` to create DTO with nested associations
   - This method automatically handles transformation of notes and generated_plans

3. **Implement JSON Response:**
   - Use `respond_to` block for format handling
   - For JSON format: `render json: { trip: dto.serialize }, status: :ok`
   - Follow existing pattern from `create` and `index` actions

4. **Implement HTML Response (Optional):**
   - For HTML format: `render :show`
   - View template should already exist at `app/views/trips/show.html.erb`
   - If view doesn't exist, create basic view showing trip details

5. **Add Route Verification:**
   - Verify route is defined in `config/routes.rb` (should already exist: `resources :trips`)
   - Route should map to `trips#show` with `:id` parameter

6. **Testing Considerations:**
   - Test successful retrieval of own trip
   - Test 404 when trip doesn't exist
   - Test 404 when trip belongs to different user (authorization)
   - Test 401 when user not authenticated
   - Test JSON response format matches API specification
   - Test HTML response renders correctly
   - Test eager loading prevents N+1 queries (use `Bullet` gem in development or query logging)

7. **Error Handling Verification:**
   - Verify `rescue_from ActiveRecord::RecordNotFound` in ApplicationController handles 404s
   - Verify error response format matches `ErrorResponseDTO` structure
   - Verify logging occurs for errors

8. **Performance Testing:**
   - Verify eager loading is working (check SQL logs)
   - Test with trips that have many notes/generated_plans
   - Verify response times are acceptable

### Code Structure Example:

```ruby
# GET /trips/:id
# Retrieves a specific trip with its notes and generated plans
# Returns 200 OK with trip data on success, 404 on not found
sig { void }
def show
  # Find trip scoped to current user (prevents unauthorized access)
  @trip = current_user.trips.includes(:notes, :generated_plans).find(params[:id])

  # Respond based on requested format
  respond_to do |format|
    format.json do
      dto = DTOs::TripDTO.from_model_with_associations(@trip)
      render json: { trip: dto.serialize }, status: :ok
    end
    format.html { render :show }
  end
rescue ActiveRecord::RecordNotFound
  # This is handled by ApplicationController#handle_not_found via rescue_from
  # Explicit rescue is optional but can be included for clarity
  raise
end
```

### Alternative Implementation (Using Helper Method):

```ruby
# GET /trips/:id
sig { void }
def show
  @trip = current_user.trips.includes(:notes, :generated_plans).find(params[:id])

  respond_to do |format|
    format.json do
      render_model_json(
        @trip,
        dto_class: DTOs::TripDTO,
        transform_method: :from_model_with_associations,
        status: :ok
      )
      # Note: render_model_json doesn't wrap in { trip: ... }, so adjust or create wrapper
      # Better to use explicit render as shown above
    end
    format.html { render :show }
  end
end
```

### Notes on Implementation:

- The `rescue_from ActiveRecord::RecordNotFound` in `ApplicationController` will automatically catch any `RecordNotFound` exception raised by `find`
- Using `current_user.trips` ensures proper authorization - if the trip belongs to another user, ActiveRecord will raise `RecordNotFound` when it can't find the trip in the scoped collection
- The `includes(:notes, :generated_plans)` ensures eager loading to prevent N+1 queries
- The `from_model_with_associations` method on `TripDTO` handles all nested transformations automatically
- Follow the existing pattern from `index` and `create` actions for consistency

