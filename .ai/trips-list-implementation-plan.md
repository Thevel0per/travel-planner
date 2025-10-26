# API Endpoint Implementation Plan: List Trips

## 1. Endpoint Overview

The List Trips endpoint retrieves all trips belonging to the authenticated user with support for pagination, sorting, and filtering. This is a read-only operation that returns trip resources along with aggregate counts (notes_count, generated_plans_count) and pagination metadata. The endpoint serves both JSON API responses and HTML views for the fullstack application.

**Key Features:**
- User-scoped trip listing (security: users only see their own trips)
- Pagination support with configurable page size
- Multi-field sorting (start_date, created_at, destination)
- Destination filtering with partial matching
- Aggregate counts for related resources
- Dual format support (JSON API + HTML view)

## 2. Request Details

- **HTTP Method:** `GET`
- **URL Structure:** `/trips`
- **Authentication:** Required (Devise session via `before_action :authenticate_user!`)

### Query Parameters:

#### Optional Parameters:

| Parameter     | Type    | Default | Validation                | Description                                              |
|---------------|---------|---------|---------------------------|----------------------------------------------------------|
| `page`        | Integer | `1`     | Must be positive integer  | Page number for pagination                               |
| `per_page`    | Integer | `20`    | Must be between 1 and 100 | Number of items per page                                 |
| `sort_order`  | String  | `asc`   | Must be: `asc` or `desc`  | Sort order by start_date (ascending or descending)       |
| `destination` | String  | `nil`   | Sanitized string          | Filter by destination (partial match, case-insensitive)  |

### Request Body:
None (GET request)

### Request Examples:

**Basic request (defaults):**
```
GET /trips
```

**With pagination:**
```
GET /trips?page=2&per_page=10
```

**With sorting:**
```
GET /trips?sort_order=desc
```

**With filtering:**
```
GET /trips?destination=paris
```

**Combined:**
```
GET /trips?page=1&per_page=20&sort_order=asc&destination=france
```

## 3. Used Types

### DTOs (Data Transfer Objects):

**Primary Response DTOs:**
- `DTOs::TripDTO` - Represents a single trip resource
  - Factory method: `from_model(trip)` - converts Trip model to DTO
  - Fields: id, name, destination, start_date, end_date, number_of_people, created_at, updated_at

- `DTOs::PaginationMetaDTO` - Pagination metadata
  - Factory method: `from_collection(trips)` - builds from paginated collection
  - Fields: current_page, total_pages, total_count, per_page

**Error Response DTO:**
- `DTOs::ErrorResponseDTO` - Error response structure
  - Factory methods: `single_error(message)`, `validation_errors(errors_hash)`
  - Fields: errors (array of error objects with field and message)

### Command Models:
None required (read-only endpoint)

### Model Enums:
None directly used (no enum filtering in this endpoint)

## 4. Response Details

### Success Response (200 OK):

**JSON Format:**
```json
{
  "trips": [
    {
      "id": 1,
      "name": "Summer Vacation 2025",
      "destination": "Paris, France",
      "start_date": "2025-07-15",
      "end_date": "2025-07-22",
      "number_of_people": 2,
      "created_at": "2025-10-19T12:00:00Z",
      "updated_at": "2025-10-19T12:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 45,
    "per_page": 20
  }
}
```

**HTML Format:**
- Renders `trips/index.html.erb` view
- View receives `@trips` (paginated collection) and `@meta` (pagination metadata)
- Includes links to trip details, create new trip, and pagination controls

### Error Responses:

**401 Unauthorized:**
```json
{
  "errors": [
    {
      "field": "authentication",
      "message": "You need to sign in or sign up before continuing."
    }
  ]
}
```

**400 Bad Request (Invalid Parameters):**
```json
{
  "errors": [
    {
      "field": "per_page",
      "message": "must be between 1 and 100"
    }
  ]
}
```

**500 Internal Server Error:**
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
1. HTTP Request (GET /trips?params)
   ↓
2. Rails Router → TripsController#index
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. Validate & sanitize query parameters
   ↓
5. Build base query: current_user.trips
   ↓
6. Apply destination filter (if provided)
   ↓
7. Apply sorting (default: start_date asc)
   ↓
8. Apply pagination (using kaminari or pagy gem)
   ↓
9. Load trips with aggregate counts (notes_count, generated_plans_count)
   ↓
10. Transform each Trip model → TripDTO
   ↓
11. Build PaginationMetaDTO from paginated collection
   ↓
12. Respond based on format:
    - JSON: render json with trips array + meta
    - HTML: render index view with @trips and @meta
```

### Database Queries:

**Primary Query (with counts):**
```ruby
current_user.trips
  .left_joins(:notes, :generated_plans)
  .select(
    'trips.*',
    'COUNT(DISTINCT notes.id) as notes_count',
    'COUNT(DISTINCT generated_plans.id) as generated_plans_count'
  )
  .group('trips.id')
  .where(destination_filter)  # if provided
  .order(sort_clause)
  .page(page)
  .per(per_page)
```


### External Service Interactions:
None (pure database read operation)

## 6. Security Considerations

### Authentication:
- **Devise Integration:** Use `before_action :authenticate_user!` to ensure user is signed in
- **Session-based:** Relies on Devise session cookie
- **Redirect on failure:** Unauthenticated requests redirect to sign-in page (HTML) or return 401 (JSON)

### Authorization:
- **User Scoping:** CRITICAL - Always scope to `current_user.trips` to prevent unauthorized access to other users' trips
- **No shared trips:** Current design has no trip sharing, so strict user ownership applies
- **Implicit authorization:** By scoping to current_user, authorization is built into query

### Input Validation & Sanitization:

**SQL Injection Prevention:**
- Use ActiveRecord parameterized queries for destination filter
- NEVER use raw SQL interpolation
- Example: `where('destination ILIKE ?', "%#{sanitized_destination}%")`

**Parameter Validation:**
```ruby
# Validate sort_order parameter
ALLOWED_SORT_ORDERS = %w[asc desc].freeze

# Validate numeric ranges
per_page = params[:per_page].to_i.clamp(1, 100)
page = [params[:page].to_i, 1].max
```

**XSS Prevention:**
- Rails escapes HTML by default in views
- Ensure destination filter output is escaped in views
- Use `sanitize` or `h()` helper for user-generated content display

### Rate Limiting:
- Consider implementing rate limiting (e.g., Rack::Attack)
- Prevent abuse of pagination endpoint
- Limit: 100 requests per minute per user

### HTTPS:
- Ensure production environment enforces HTTPS
- Set `force_ssl = true` in production.rb

## 7. Error Handling

### Error Scenarios & Status Codes:

| Scenario | Status Code | Response | Handling |
|----------|-------------|----------|----------|
| User not authenticated | 401 Unauthorized | ErrorResponseDTO with authentication error | Devise handles redirect/JSON response |
| Invalid per_page (> 100 or < 1) | 400 Bad Request | ErrorResponseDTO with validation error | Validate in controller, return early |
| Invalid sort_order value | 400 Bad Request | ErrorResponseDTO with validation error | Validate against whitelist |
| Invalid page number (< 1) | 400 Bad Request | ErrorResponseDTO with validation error | Clamp to minimum of 1 |
| Database connection error | 500 Internal Server Error | Generic error message | Log full error, return sanitized message |
| Unexpected exception | 500 Internal Server Error | Generic error message | Log with backtrace, alert monitoring |

### Error Handling Implementation:

```ruby
# In controller
rescue_from StandardError, with: :handle_server_error
rescue_from ActionController::ParameterMissing, with: :handle_bad_request

private

def handle_bad_request(exception)
  error = DTOs::ErrorResponseDTO.single_error(exception.message)
  respond_to do |format|
    format.json { render json: error.serialize, status: :bad_request }
    format.html { 
      flash[:error] = exception.message
      redirect_to trips_path 
    }
  end
end

def handle_server_error(exception)
  Rails.logger.error("Unexpected error in TripsController#index: #{exception.message}")
  Rails.logger.error(exception.backtrace.join("\n"))
  
  error = DTOs::ErrorResponseDTO.single_error("An unexpected error occurred")
  respond_to do |format|
    format.json { render json: error.serialize, status: :internal_server_error }
    format.html { 
      flash[:error] = "An unexpected error occurred"
      redirect_to root_path 
    }
  end
end
```

### Logging Strategy:

**What to Log:**
- Invalid parameter attempts (potential attack indicators)
- Database query errors
- Unexpected exceptions with full backtrace
- Authentication failures (via Devise)

**What NOT to Log:**
- Sensitive user data
- Full trip content in production
- Authentication tokens/sessions

**Logging Levels:**
- INFO: Successful requests with basic metrics (count, duration)
- WARN: Invalid parameters, validation failures
- ERROR: Database errors, unexpected exceptions
- FATAL: Critical system failures

## 8. Performance Considerations

### Potential Bottlenecks:

1. **Large Result Sets:** Users with hundreds of trips
   - **Solution:** Enforce pagination (max 100 per page) using Pagy gem

2. **Filtering on destination:** ILIKE can be slow on large datasets
   - **Solution:** Add database index on destination column, consider GIN index for PostgreSQL

3. **Sorting performance:** Sorting by date on large datasets
   - **Solution:** Add database index on `start_date` column

### Optimization Strategies:

**Query Optimization:**
- Scope queries to `current_user.trips` to leverage indexes
- Use ActiveRecord parameterized queries to prevent SQL injection
- Keep queries simple - only fetch needed data

**Pagination:**
- Use Pagy gem (lightweight, fastest pagination solution)
- Default: 20 items per page, maximum: 100 items per page

### Performance Targets:
- **Response Time:** < 200ms for typical request (20 trips)
- **Database Query Time:** < 50ms
- **Support:** Handle users with 1000+ trips efficiently

## 9. Implementation Steps

### Step 1: Setup Routes and Controller
- Add trips resource route to `config/routes.rb` with `:index` action
- Set trips#index as root path
- Generate TripsController if it doesn't exist using Rails generator

### Step 2: Add Pagy Gem for Pagination
- Add `pagy` gem to Gemfile
- Run `bundle install`
- Include Pagy backend in ApplicationController
- Include Pagy frontend helper in ApplicationHelper

### Step 3: Create Service Object for Query Logic
- Create `app/services/trips_query_service.rb`
- Define constants for allowed sort orders, defaults, and pagination limits
- Implement validation for query parameters (sort_order, per_page)
- Implement `#call` method that builds the query (filtering, sorting)
- Implement helper methods for pagination (page, per_page)
- Keep controller thin by extracting all query logic to this service

### Step 4: Implement Controller Index Action
- Add `before_action :authenticate_user!` for Devise authentication
- Create `#index` action that:
  - Instantiates TripsQueryService with current_user and params
  - Validates parameters and handles errors
  - Applies pagination using Pagy
  - Responds to both HTML and JSON formats
- Implement private helper methods:
  - `#render_json_response` - transforms trips to DTOs and builds JSON
  - `#render_html_response` - prepares data for view
  - `#handle_validation_errors` - returns 400 with error DTO
  - `#handle_server_error` - catches exceptions, logs, returns 500

### Step 5: Create HTML Views with Tailwind CSS
- Create `app/views/trips/index.html.erb` with:
  - Header with "New Trip" button
  - Search/filter form (destination filter, sort_order dropdown)
  - Trip cards grid (responsive layout)
  - Pagy pagination controls
  - Empty state for users with no trips
- Create `app/views/trips/_trip_card.html.erb` partial with:
  - Trip name, destination, dates, number of people
  - View and Edit links

### Step 6: Write RSpec Tests
- Create `spec/requests/trips_spec.rb` with test cases for:
  - Authentication (authenticated vs unauthenticated users)
  - Basic listing functionality
  - Pagination (metadata, multiple pages)
  - Filtering (destination partial match)
  - Sorting (asc/desc by start_date)
  - Invalid parameters (per_page > 100, invalid sort_order)
  - Both JSON and HTML format responses

### Step 7: Manual Testing
- Follow manual testing checklist to verify:
  - Authentication and authorization
  - All query parameters work correctly
  - Error handling for invalid inputs
  - Performance with large datasets
  - UI/UX in browser
  - JSON API responses

### Step 8: Optional Performance Testing
- Create benchmark script to measure query performance
- Test with realistic data volumes (100-1000 trips)
- Verify response times meet targets (< 200ms)

### Step 9: Documentation
- Document API endpoint in project documentation
- Include request/response examples
- Document error codes and scenarios

### Step 10: Deploy and Monitor
- Run migrations in production
- Verify indexes are created
- Monitor error rates and response times
- Set up alerts for issues

---

## Summary

This implementation plan provides comprehensive guidance for implementing the List Trips endpoint with:

✅ **Security:** Authentication via Devise, user scoping, input validation, SQL injection prevention
✅ **Performance:** Database indexes, counter caches, pagination, optimized queries
✅ **Error Handling:** Comprehensive error scenarios with proper status codes
✅ **Type Safety:** Full integration with Sorbet DTOs and Commands
✅ **Testing:** RSpec request specs covering all scenarios
✅ **Documentation:** Inline code comments and API documentation
✅ **Dual Format Support:** Both JSON API and HTML views
✅ **Rails Conventions:** Following RESTful routing and Rails best practices

The implementation follows all workspace rules and leverages Rails generators and conventions for a clean, maintainable solution.

