# API Endpoint Implementation Plan: Update Note

## 1. Endpoint Overview

The Update Note endpoint allows authenticated users to modify the content of an existing note associated with one of their trips. This endpoint follows RESTful conventions and supports both HTML and JSON response formats for seamless integration with the Hotwire-based frontend.

**Purpose:**
- Update the content of an existing note
- Ensure proper authorization (note must belong to user's trip)
- Validate input according to business rules
- Return updated note data in standardized format

**Key Characteristics:**
- Nested resource under trips (notes belong to trips)
- Requires authentication via Devise session
- Supports partial updates (only content field can be updated)
- Returns 200 OK on success, 404 on not found, 422 on validation errors

## 2. Request Details

### HTTP Method
- `PUT` or `PATCH` (Rails treats both identically for updates)

### URL Structure
```
PUT/PATCH /trips/:trip_id/notes/:id
```

### Path Parameters
- **Required:**
  - `trip_id` (Integer): ID of the trip that owns the note
  - `id` (Integer): ID of the note to update

### Request Body
```json
{
  "note": {
    "content": "Visit Eiffel Tower at sunset - book tickets in advance"
  }
}
```

**Body Parameters:**
- **Required:**
  - `content` (String): The updated note content
    - Cannot be blank
    - Maximum length: 10,000 characters

**Note:** The `note` wrapper key is optional - the command object handles both nested (`params[:note]`) and flat parameter formats.

### Request Headers
- `Content-Type: application/json` (for JSON requests)
- `Accept: application/json` (for JSON responses)
- Session cookie (automatically included by browser for authentication)
- CSRF token (automatically handled by Rails/Turbo)

## 3. Used Types

### Command Models
- **`Commands::NoteUpdateCommand`** (already exists)
  - Purpose: Parse and validate request parameters
  - Fields: `content` (String, required)
  - Methods:
    - `from_params(params)` - Creates command from request parameters
    - `to_model_attributes` - Converts to hash for ActiveRecord update

### Data Transfer Objects
- **`DTOs::NoteDTO`** (already exists)
  - Purpose: Serialize note data for JSON responses
  - Fields: `id`, `trip_id`, `content`, `created_at`, `updated_at`
  - Methods:
    - `from_model(note)` - Creates DTO from Note model
    - `serialize` - Converts to hash for JSON rendering

- **`DTOs::ErrorResponseDTO`** (already exists)
  - Purpose: Standardize error response format
  - Methods:
    - `from_model_errors(model)` - Converts ActiveRecord errors to DTO
    - `single_error(message)` - Creates single error message DTO
    - `serialize` - Converts to hash for JSON rendering

## 4. Response Details

### Success Response (200 OK)

**JSON Format:**
```json
{
  "note": {
    "id": 1,
    "trip_id": 1,
    "content": "Visit Eiffel Tower at sunset - book tickets in advance",
    "created_at": "2025-10-19T12:00:00Z",
    "updated_at": "2025-10-19T14:00:00Z"
  }
}
```

**HTML Format:**
- For Turbo Stream requests: Updates the note in the DOM
- For standard HTML requests: Redirects to trip show page with flash message
- Flash message: "Note updated successfully"

### Error Responses

#### 401 Unauthorized (Not Authenticated)
**Triggered When:**
- User session expired or invalid
- User not logged in
- Devise authentication fails

**Handling:**
- Handled automatically by `before_action :authenticate_user!`
- JSON: Returns Devise's standard unauthorized response
- HTML: Redirects to sign-in page

#### 404 Not Found
**Triggered When:**
- Note with given `id` does not exist
- Trip with given `trip_id` does not exist
- Note does not belong to the specified trip
- Trip does not belong to the authenticated user

**Error Format:**
```json
{
  "error": "Resource not found"
}
```

**Implementation:**
- Handled by `ApplicationController#handle_not_found` rescue handler
- Uses `current_user.trips.find(params[:trip_id])` to ensure trip ownership
- Uses `@trip.notes.find(params[:id])` to ensure note belongs to trip
- Raises `ActiveRecord::RecordNotFound` which is caught by rescue handler
- Returns generic "Resource not found" message (prevents resource enumeration)

#### 422 Unprocessable Content (Validation Errors)
**Triggered When:**
- `content` is blank or empty
- `content` exceeds 10,000 characters
- Missing `content` field in request body

**Error Format:**
```json
{
  "errors": {
    "content": ["can't be blank"]
  }
}
```

**Implementation:**
- Validation performed by ActiveRecord model (`Note` model)
- Use `ErrorResponseDTO.from_model_errors(@note)` to convert errors
- Status code: `422` (Rails convention for validation errors)
- Do not log validation errors as warnings (expected user input issues)

#### 500 Internal Server Error
**Triggered When:**
- Database connection failures
- Unexpected exceptions during update operation
- Foreign key constraint violations (should be prevented by proper authorization)

**Error Format:**
```json
{
  "error": "An unexpected error occurred"
}
```

**Implementation:**
- Log full exception details to `Rails.logger.error`
- Return generic error message to client (do not expose internal details)
- Status code: `500`

## 5. Data Flow

### Request Processing Flow

```
1. HTTP Request (PUT/PATCH /trips/:trip_id/notes/:id)
   ↓
2. Rails Router → Trips::NotesController#update
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. before_action :set_trip
   - current_user.trips.find(params[:trip_id])
   - Raises ActiveRecord::RecordNotFound if trip doesn't exist or doesn't belong to user
   ↓
5. before_action :set_note
   - @trip.notes.find(params[:id])
   - Raises ActiveRecord::RecordNotFound if note doesn't exist or doesn't belong to trip
   ↓
6. Parse Request Parameters
   - Commands::NoteUpdateCommand.from_params(params.permit!.to_h)
   - Handles both nested (params[:note]) and flat parameter formats
   ↓
7. Convert Command to Model Attributes
   - command.to_model_attributes
   - Returns { content: "..." }
   ↓
8. Update Note
   - @note.update(attributes)
   - ActiveRecord runs model validations automatically
   ↓
9a. If Update Succeeds:
    - Transform Note → NoteDTO using from_model
    - Render JSON: { note: dto.serialize }, status: 200
    - Or render Turbo Stream/HTML response
   ↓
9b. If Validation Fails:
    - Transform errors → ErrorResponseDTO using from_model_errors
    - Render JSON: error_dto.serialize, status: 422
    - Or render Turbo Stream/HTML with errors
```

### Authorization Flow

```
1. User Authentication Check
   - Devise validates session cookie
   - Sets current_user if valid
   ↓
2. Trip Ownership Verification
   - current_user.trips.find(params[:trip_id])
   - Ensures trip belongs to authenticated user
   - Returns 404 if not found (prevents enumeration)
   ↓
3. Note Ownership Verification
   - @trip.notes.find(params[:id])
   - Ensures note belongs to the trip
   - Returns 404 if not found (prevents enumeration)
```

### Database Operations

1. **Trip Lookup:**
   - Query: `SELECT * FROM trips WHERE id = ? AND user_id = ?`
   - Uses index on `user_id` (from schema)
   - Single query, very fast

2. **Note Lookup:**
   - Query: `SELECT * FROM notes WHERE id = ? AND trip_id = ?`
   - Uses index on `trip_id` (from schema)
   - Single query, very fast

3. **Note Update:**
   - Query: `UPDATE notes SET content = ?, updated_at = ? WHERE id = ?`
   - Single record update, very fast
   - No cascading updates needed

## 6. Security Considerations

### Authentication
- **Required:** All requests must be authenticated via Devise session
- **Implementation:** `before_action :authenticate_user!` in controller
- **Failure Handling:** Returns 401 Unauthorized or redirects to login

### Authorization
- **Trip Ownership:** Users can only update notes for their own trips
- **Implementation:** Use `current_user.trips.find(params[:trip_id])` to scope trip lookup
- **Note Ownership:** Notes must belong to the specified trip
- **Implementation:** Use `@trip.notes.find(params[:id])` to scope note lookup
- **Security Benefit:** Returns 404 instead of 403 to prevent resource enumeration

### Input Validation
- **Strong Parameters:** Use `params.permit!.to_h` (command object handles filtering)
- **Command Object:** `NoteUpdateCommand` validates and sanitizes input
- **Model Validation:** ActiveRecord validations enforce business rules
  - Content presence validation
  - Content length validation (max 10,000 characters)

### CSRF Protection
- **Enabled:** Rails CSRF protection enabled by default
- **Turbo Handling:** Turbo automatically includes CSRF token in requests
- **JSON Requests:** CSRF token verified on all state-changing requests

### Data Exposure
- **Error Messages:** Generic error messages for 404/500 (don't expose internal details)
- **Validation Errors:** Specific field-level errors for 422 (helpful for user feedback)
- **Response Data:** Only returns data user is authorized to see

### SQL Injection Prevention
- **ActiveRecord:** All queries use parameterized statements
- **No Raw SQL:** No raw SQL queries in this endpoint
- **Safe:** ActiveRecord automatically escapes all parameters

### XSS Prevention
- **Content Storage:** Note content stored as-is (no HTML rendering in API)
- **Frontend Responsibility:** Frontend must properly escape content when displaying
- **JSON Encoding:** Rails automatically escapes JSON output

## 7. Performance Considerations

### Database Performance
- **Indexes:** Both `trips.user_id` and `notes.trip_id` are indexed (from schema)
- **Query Efficiency:** Single record lookups are very fast
- **No N+1 Queries:** Not loading associations, so no N+1 concerns
- **Update Operation:** Single UPDATE query, minimal overhead

### Response Size
- **Minimal Payload:** Response contains only note data (small JSON object)
- **No Large Data:** Note content limited to 10,000 characters (reasonable size)
- **No Pagination:** Single record response, no pagination overhead

### Caching
- **Not Applicable:** Update operations invalidate caches, so caching not beneficial
- **Future Consideration:** Could cache note lists for read operations

### Potential Bottlenecks
- **None Expected:** Simple update operation with proper indexing
- **Database Connection Pool:** Standard Rails connection pooling handles concurrent requests
- **Validation Checks:** Lightweight validations (presence, length) are very fast

### Optimization Strategies
- **Already Optimized:** Uses indexed lookups, minimal queries
- **No Further Optimization Needed:** Endpoint is simple and efficient
- **Monitoring:** Monitor query performance if issues arise (unlikely)

## 8. Implementation Steps

1. **Add Route:**
   - Update `config/routes.rb` to include `:update` in notes resources
   - Change `resources :notes, only: [:create]` to `resources :notes, only: [:create, :update]`
   - Verify route: `PUT/PATCH /trips/:trip_id/notes/:id`

2. **Add `set_note` Before Action:**
   - Add `before_action :set_note, only: [:update]` to `Trips::NotesController`
   - Implement `set_note` method:
     ```ruby
     def set_note
       @note = @trip.notes.find(params[:id])
     end
     ```
   - `ActiveRecord::RecordNotFound` will be caught by `ApplicationController#handle_not_found`

3. **Implement `update` Action:**
   - Add method signature with `sig { void }` for Sorbet typing
   - Parse request parameters using `Commands::NoteUpdateCommand.from_params(params.permit!.to_h)`
   - Convert command to model attributes using `command.to_model_attributes`
   - Update note using `@note.update(attributes)`

4. **Handle Success Response:**
   - Transform updated note to DTO: `DTOs::NoteDTO.from_model(@note)`
   - Render JSON response: `render json: { note: dto.serialize }, status: :ok`
   - For Turbo Stream: Update note in DOM (if Turbo Stream view exists)
   - For HTML: Set flash message and redirect to trip show page

5. **Handle Validation Errors:**
   - Check `@note.errors.any?` after update attempt
   - Transform errors to DTO: `DTOs::ErrorResponseDTO.from_model_errors(@note)`
   - Render JSON error response: `render json: error_dto.serialize, status: :unprocessable_content`
   - For Turbo Stream: Re-render form with errors (if Turbo Stream view exists)
   - For HTML: Re-render edit form with errors

6. **Add Response Format Handling:**
   - Use `respond_to` block to handle JSON, Turbo Stream, and HTML formats
   - Follow existing pattern from `create` action in same controller
   - Ensure consistent response format across all formats

7. **Test Implementation:**
   - Test successful update with valid content
   - Test validation errors (blank content, content too long)
   - Test authorization (note from different trip, trip from different user)
   - Test authentication (unauthenticated requests)
   - Test error responses (404, 422, 500)

8. **Verify Error Handling:**
   - Ensure `ActiveRecord::RecordNotFound` is properly caught
   - Verify error messages are user-friendly
   - Confirm no sensitive information leaked in error responses

9. **Update Documentation:**
   - Ensure API documentation reflects the new endpoint
   - Update any frontend documentation if needed

10. **Code Review Checklist:**
    - Follows existing controller patterns
    - Uses command objects for parameter parsing
    - Uses DTOs for response serialization
    - Proper error handling
    - Security best practices followed
    - No N+1 queries
    - Proper authorization checks

