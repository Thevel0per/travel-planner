# API Endpoint Implementation Plan: Delete Note (DELETE /trips/:trip_id/notes/:id)

## 1. Endpoint Overview

This endpoint deletes an existing note for a trip belonging to the authenticated user. The deletion operation is straightforward - it permanently removes the note from the database. The endpoint ensures that users can only delete notes that belong to their own trips through proper authorization scoping.

**Purpose:** Allow users to permanently remove notes from their trips.

**Authentication:** Required (Devise session-based authentication)

**HTTP Method:** `DELETE`

**Authorization:** The note must belong to a trip owned by the authenticated user.

## 2. Request Details

- **HTTP Method:** `DELETE`
- **URL Structure:** `/trips/:trip_id/notes/:id`
- **Parameters:**
  - **Required:**
    - `trip_id` (route parameter) - Integer ID of the trip that owns the note
    - `id` (route parameter) - Integer ID of the note to delete
  - **Optional:** None
- **Request Body:** Not applicable (DELETE requests typically don't have request bodies)
- **Content-Type:** Not required for DELETE requests (no body)
- **Accept:** `application/json` or `text/html` (via Accept header or format parameter)

## 3. Used Types

### DTOs (Data Transfer Objects)
- **ErrorResponseDTO** - For error responses (404, 500)
  - Uses `single_error` method for simple error messages
  - No success DTO needed - returns simple message hash

### Command Models
- None required (DELETE endpoint has no request body or input parameters to parse)

### Enums
- None required for this endpoint

## 4. Response Details

### Success Response (200 OK)

**JSON Format:**
```json
{
  "message": "Note deleted successfully"
}
```

**HTML Format:**
- Redirects to trip show page (`trip_path(@trip)`) with success flash message
- Flash message: `flash[:notice] = 'Note deleted successfully'`

**Turbo Stream Format:**
- Returns Turbo Stream response to remove the note from the DOM
- Flash message: `flash.now[:notice] = 'Note deleted successfully'`

### Error Responses

**401 Unauthorized (Not Authenticated):**
- Handled automatically by Devise `before_action :authenticate_user!`
- JSON: Returns Devise's standard unauthorized response
- HTML: Redirects to sign-in page

**404 Not Found:**
- Note doesn't exist or doesn't belong to the authenticated user's trip
- Handled by `ApplicationController#handle_not_found` rescue handler (via `rescue_from ActiveRecord::RecordNotFound`)
```json
{
  "error": "Resource not found"
}
```

**500 Internal Server Error:**
- Unexpected server-side errors (database failures, transaction errors, etc.)
- Handled by `ApplicationController#handle_server_error` (if implemented) or Rails default error handling
```json
{
  "error": "An unexpected error occurred"
}
```

## 5. Data Flow

### Request Processing Flow:

```
1. HTTP Request (DELETE /trips/:trip_id/notes/:id)
   ↓
2. Rails Router → Trips::NotesController#destroy
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. before_action :set_trip
   - current_user.trips.find(params[:trip_id])
   ↓
5. before_action :set_note
   - @trip.notes.find(params[:id])
   ↓
6. Delete note
   - @note.destroy
   ↓
7. Check if deletion succeeded:
   - If successful: Return success message
   - If failed: Handle error (transaction rollback, etc.)
   ↓
8. Respond based on format:
   - JSON: render json: { message: "Note deleted successfully" }, status: :ok
   - HTML: redirect_to trip_path(@trip), notice: 'Note deleted successfully'
   - Turbo Stream: render turbo_stream response to remove note from DOM
```

### Database Queries:

**Primary Query (find trip):**
```ruby
current_user.trips.find(params[:trip_id])
```

**Expected SQL:**
```sql
SELECT "trips".* FROM "trips" 
WHERE "trips"."user_id" = ? AND "trips"."id" = ? 
LIMIT 1
```

**Secondary Query (find note):**
```ruby
@trip.notes.find(params[:id])
```

**Expected SQL:**
```sql
SELECT "notes".* FROM "notes" 
WHERE "notes"."trip_id" = ? AND "notes"."id" = ? 
LIMIT 1
```

**Deletion Query:**
```ruby
@note.destroy
```

**Expected SQL:**
```sql
DELETE FROM "notes" WHERE "notes"."id" = ?
```

### Authorization Flow:

The authorization is enforced through the nested resource lookup:
1. First, find the trip scoped to `current_user.trips` - ensures user owns the trip
2. Then, find the note scoped to `@trip.notes` - ensures note belongs to the trip
3. If either lookup fails, `ActiveRecord::RecordNotFound` is raised and caught by `ApplicationController#handle_not_found`

## 6. Security Considerations

### Authentication
- **Required:** All requests must be authenticated via Devise session
- **Enforcement:** `before_action :authenticate_user!` in controller
- **Unauthenticated Access:** Returns 401 Unauthorized (JSON) or redirects to sign-in (HTML)

### Authorization
- **Trip Ownership:** Notes can only be deleted if the trip belongs to the authenticated user
- **Enforcement:** 
  - `set_trip` uses `current_user.trips.find(params[:trip_id])` - raises `RecordNotFound` if trip doesn't belong to user
  - `set_note` uses `@trip.notes.find(params[:id])` - raises `RecordNotFound` if note doesn't belong to trip
- **Result:** Users cannot delete notes from trips they don't own

### Input Validation
- **Route Parameters:** Validated by Rails routing (must be integers)
- **Parameter Tampering:** Protected by scoped queries (user can only access their own trips)
- **SQL Injection:** Protected by ActiveRecord parameterized queries

### CSRF Protection
- **Rails Default:** CSRF tokens required for all non-GET requests
- **JSON API:** CSRF protection can be disabled for JSON requests if using API-only mode, but this app uses session-based auth so CSRF is enforced

### Data Integrity
- **Foreign Key Constraints:** Database enforces `notes.trip_id` foreign key constraint
- **Cascading:** No cascading deletes needed (notes are leaf nodes in the data model)

## 7. Error Handling

### Error Scenarios and Status Codes

| Error Scenario | Status Code | Handler | Response Message |
|----------------|-------------|---------|------------------|
| User not authenticated | 401 | Devise | Standard Devise unauthorized response |
| Trip not found or doesn't belong to user | 404 | `handle_not_found` | "Resource not found" |
| Note not found or doesn't belong to trip | 404 | `handle_not_found` | "Resource not found" |
| Database connection error | 500 | `handle_server_error` | "An unexpected error occurred" |
| Transaction rollback error | 500 | `handle_server_error` | "An unexpected error occurred" |
| Foreign key constraint violation | 500 | `handle_server_error` | "An unexpected error occurred" |
| Unexpected exception | 500 | `handle_server_error` | "An unexpected error occurred" |

### Deletion Error Handling:

The `destroy` method in ActiveRecord performs the deletion within a database transaction. If any part of the deletion fails (e.g., foreign key constraint), the entire transaction is rolled back, and the note remains unchanged.

**Implementation:**
- Call `@note.destroy` - returns `true` if successful, `false` if failed
- Check `@note.destroyed?` to verify deletion
- In rare cases, `destroy` may raise an exception (caught by global error handler)

**Note:** Since notes have no dependent associations, deletion should always succeed unless there's a database-level constraint violation.

### Error Logging:

- **404 Errors:** Logged at WARN level via `ApplicationController#handle_not_found`
  - Includes controller, action, and exception message
- **500 Errors:** Logged at ERROR level via `ApplicationController#handle_server_error`
  - Includes full exception message and backtrace
- **Rails Logger:** All errors logged to `log/development.log` (development) or application logs (production)

### Error Response Format:

**Single Error (404, 500):**
```json
{
  "error": "Resource not found"
}
```

For HTML requests, errors are displayed via flash messages and redirects.

## 8. Performance Considerations

### Optimization Strategies:

1. **Database Indexing:**
   - `notes.id` is automatically indexed (primary key)
   - `notes.trip_id` is indexed (foreign key) - ensures fast lookup of notes by trip
   - No additional indexes needed for this operation

2. **Query Efficiency:**
   - Two queries required: one to find trip, one to find note
   - Both queries use indexed columns and are highly efficient
   - No N+1 queries or eager loading needed for deletion

3. **Transaction Overhead:**
   - `destroy` method runs within a database transaction
   - Minimal overhead for single record deletion
   - Transaction ensures atomicity (all-or-nothing)

4. **Caching:**
   - No caching needed for deletion operations
   - Deletion invalidates any cached data automatically

5. **Scalability:**
   - Deletion is a simple, fast operation
   - No complex joins or aggregations
   - Performance remains consistent as data grows

### Potential Bottlenecks:

- **None identified** - This is a straightforward deletion operation with minimal complexity

### Future Optimization Opportunities:

- None required for this simple endpoint

## 9. Implementation Steps

1. **Update Routes:**
   - Add `:destroy` to the notes resource in `config/routes.rb`
   - Change `resources :notes, only: [ :create, :update ]` to `resources :notes, only: [ :create, :update, :destroy ]`
   - Verify route helper `trip_note_path(trip, note, method: :delete)` is available

2. **Update `before_action` Filter:**
   - Add `:destroy` to the `set_note` before_action in `Trips::NotesController`
   - Change `before_action :set_note, only: [ :update ]` to `before_action :set_note, only: [ :update, :destroy ]`
   - Ensure `set_note` uses `@trip.notes.find(params[:id])` for authorization

3. **Add `destroy` Action to `Trips::NotesController`:**
   - Add method signature with `sig { void }` for Sorbet typing
   - Call `@note.destroy` to delete the note
   - The `destroy` method returns `true` if successful, `false` if validation prevents deletion (unlikely for Note model)

4. **Handle Success Response:**
   - For JSON: `render json: { message: "Note deleted successfully" }, status: :ok`
   - For HTML: `redirect_to trip_path(@trip), notice: 'Note deleted successfully'`
   - For Turbo Stream: Create `destroy.turbo_stream.erb` view to remove note from DOM
   - Use `respond_to` block to handle all three formats

5. **Error Handling (automatic):**
   - `ActiveRecord::RecordNotFound` is automatically caught by `rescue_from` in ApplicationController
   - Returns 404 with "Resource not found" message
   - Other exceptions (database errors, etc.) should be caught and handled gracefully

6. **Create Turbo Stream View (optional but recommended):**
   - Create `app/views/trips/notes/destroy.turbo_stream.erb`
   - Use `turbo_stream.remove` to remove the note element from the DOM
   - Include flash message update if needed

7. **Testing Considerations:**
   - Test successful deletion (note removed from database)
   - Test authentication requirement (401 for unauthenticated requests)
   - Test authorization (404 when trying to delete note from another user's trip)
   - Test 404 when note doesn't exist
   - Test 404 when trip doesn't exist
   - Test JSON response format
   - Test HTML response format (redirect)
   - Test Turbo Stream response format (if implemented)
   - Verify note is actually deleted from database
   - Verify trip and other notes remain unchanged

8. **Update Controller Documentation:**
   - Add RDoc/YARD comment documenting the destroy action
   - Include HTTP method, path, authentication requirements, and response formats

