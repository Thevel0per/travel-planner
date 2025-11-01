# API Endpoint Implementation Plan: Delete Trip (DELETE /trips/:id)

## 1. Endpoint Overview

This endpoint deletes an existing trip for the authenticated user. The deletion operation is cascading, meaning that all associated notes and generated plans are automatically deleted through ActiveRecord's `dependent: :destroy` association configuration. The endpoint supports both HTML and JSON response formats and ensures that users can only delete their own trips through proper authorization scoping.

**Purpose:** Allow users to permanently remove trips and all associated data (notes and generated plans) from their account.

**Authentication:** Required (Devise session-based authentication)

**HTTP Method:** `DELETE`

**Cascading Deletion:** The Trip model has `has_many :notes, dependent: :destroy` and `has_many :generated_plans, dependent: :destroy`, which ensures all associated records are automatically deleted when the trip is deleted.

## 2. Request Details

- **HTTP Method:** `DELETE`
- **URL Structure:** `/trips/:id`
- **Parameters:**
  - **Required:**
    - `id` (route parameter) - Integer ID of the trip to delete
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
  "message": "Trip deleted successfully"
}
```

**HTML Format:**
- Redirects to trips index page (`trips_path`) with success flash message
- Flash message: `flash[:notice] = 'Trip deleted successfully'`

### Error Responses

**401 Unauthorized (Not Authenticated):**
- Handled automatically by Devise `before_action :authenticate_user!`
- JSON: Returns Devise's standard unauthorized response
- HTML: Redirects to sign-in page

**404 Not Found:**
- Trip doesn't exist or doesn't belong to the authenticated user
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
1. HTTP Request (DELETE /trips/:id)
   ↓
2. Rails Router → TripsController#destroy
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. Find trip scoped to current_user (prevents unauthorized access)
   - current_user.trips.find(params[:id])
   ↓
5. Delete trip (cascades to notes and generated_plans)
   - @trip.destroy
   ↓
6. Check if deletion succeeded:
   - If successful: Return success message
   - If failed: Handle error (transaction rollback, etc.)
   ↓
7. Respond based on format:
   - JSON: render json: { message: "Trip deleted successfully" }, status: :ok
   - HTML: redirect_to trips_path, notice: 'Trip deleted successfully'
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

**Cascading Deletion (handled by ActiveRecord):**

When `@trip.destroy` is called, ActiveRecord automatically:

1. Deletes all associated notes:
```sql
DELETE FROM "notes" WHERE "notes"."trip_id" = ?
```

2. Deletes all associated generated_plans:
```sql
DELETE FROM "generated_plans" WHERE "generated_plans"."trip_id" = ?
```

3. Deletes the trip itself:
```sql
DELETE FROM "trips" WHERE "trips"."id" = ?
```

All deletions occur within a single database transaction, ensuring atomicity (all or nothing).

### External Service Interactions:
None (pure database operation)

## 6. Security Considerations

### Authentication:
- **Devise Integration:** Use `before_action :authenticate_user!` to ensure user is signed in
- **Session-based:** Relies on Devise session cookie for authentication
- **Automatic handling:** Devise handles unauthenticated requests automatically (redirects HTML, returns 401 for JSON)

### Authorization:
- **User Scoping:** CRITICAL - Always scope to `current_user.trips.find(params[:id])` to prevent unauthorized deletion of other users' trips
- **Automatic protection:** Using `current_user.trips` ensures that ActiveRecord raises `ActiveRecord::RecordNotFound` if the trip belongs to another user
- **No shared trips:** Current design has no trip sharing functionality, so strict user ownership applies
- **Route parameter validation:** Rails automatically validates `:id` is present in route, but doesn't validate format (handled by ActiveRecord when converting to integer)

### Data Validation:
- **ID Format:** ActiveRecord's `find` method handles invalid ID formats gracefully (raises `ActiveRecord::RecordNotFound`)
- **SQL Injection Protection:** ActiveRecord parameter binding prevents SQL injection
- **XSS Protection:** Rails automatically escapes JSON output, and HTML views use ERB escaping
- **Transaction Safety:** Deletion occurs within a database transaction, ensuring data consistency

### Potential Security Threats:

1. **Unauthorized Deletion Attempts:**
   - **Threat:** User attempting to delete another user's trip by guessing IDs
   - **Mitigation:** Using `current_user.trips.find` ensures trips are scoped to the authenticated user. Attempting to delete another user's trip results in 404 (not revealing trip existence).

2. **ID Enumeration:**
   - **Threat:** Malicious user enumerating trip IDs to delete trips
   - **Mitigation:** 404 responses don't reveal whether trip exists or belongs to another user. Rate limiting should be implemented at application/infrastructure level.

3. **Mass Deletion:**
   - **Threat:** Malicious user attempting to delete multiple trips rapidly
   - **Mitigation:** Rate limiting should be implemented at application/infrastructure level. Consider adding confirmation for deletion (especially for HTML requests).

4. **CSRF:**
   - **Protection:** Rails CSRF protection handles HTML form submissions. JSON API requests from authenticated sessions should verify CSRF token for state-changing operations (Rails handles this automatically for forms via `protect_from_forgery`).

5. **Cascading Deletion Safety:**
   - **Threat:** Accidental deletion of important data (notes, generated plans)
   - **Mitigation:** The `dependent: :destroy` association ensures data integrity (no orphaned records). Consider adding soft delete or audit logging if recovery is needed in the future.

## 7. Error Handling

### Error Scenarios and Handling:

| Scenario | HTTP Status | Handler | Message |
|----------|-------------|---------|---------|
| User not authenticated | 401 | Devise | Standard Devise unauthorized response |
| Trip ID missing/invalid format | 404 | `handle_not_found` | "Resource not found" |
| Trip not found | 404 | `handle_not_found` | "Resource not found" |
| Trip belongs to different user | 404 | `handle_not_found` | "Resource not found" |
| Database connection error | 500 | `handle_server_error` | "An unexpected error occurred" |
| Transaction rollback error | 500 | `handle_server_error` | "An unexpected error occurred" |
| Foreign key constraint violation | 500 | `handle_server_error` | "An unexpected error occurred" |
| Unexpected exception | 500 | `handle_server_error` | "An unexpected error occurred" |

### Deletion Error Handling:

The `destroy` method in ActiveRecord performs the deletion within a database transaction. If any part of the deletion fails (e.g., foreign key constraint), the entire transaction is rolled back, and the trip and its associations remain unchanged.

**Implementation:**
- Call `@trip.destroy` - returns `true` if successful, `false` if failed
- Check `@trip.destroyed?` to verify deletion
- In rare cases, `destroy` may raise an exception (caught by global error handler)

**Note:** ActiveRecord's `dependent: :destroy` ensures that if any associated record cannot be deleted (e.g., due to a constraint), the entire transaction fails and the trip is not deleted.

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
   - `trips.id` is automatically indexed (primary key)
   - `trips.user_id` has index for foreign key (composite index: `index_trips_on_user_id_and_destination`, `index_trips_on_user_id_and_start_date`)
   - `notes.trip_id` has index for foreign key
   - `generated_plans.trip_id` has index for foreign key
   - These indexes ensure fast lookups and cascading deletions even with large datasets

2. **Cascading Deletion Efficiency:**
   - ActiveRecord batches deletions efficiently
   - All deletions occur within a single transaction, reducing database round trips
   - Foreign key indexes help speed up the cascading DELETE operations

3. **Transaction Performance:**
   - Single transaction ensures atomicity and consistency
   - Minimal overhead compared to multiple separate DELETE operations

### Potential Bottlenecks:

- **Large Association Counts:** If a trip has many notes or generated plans (hundreds or thousands), the deletion may take longer
  - **Mitigation:** Usually negligible for typical use cases. If needed, consider batch deletion or background job processing for very large datasets
  
- **Database Locking:** The transaction may hold locks on multiple tables during deletion
  - **Mitigation:** PostgreSQL handles concurrent operations well. Deletion is typically fast for single records with reasonable association counts

### No Performance Issues Expected:

- Single record deletion operation is very fast
- Cascading deletions are efficient due to indexes
- Minimal response payload (just a message)
- No external service calls
- No N+1 queries (cascading handled by ActiveRecord)

### Future Optimization Considerations:

- If deletion becomes a bottleneck with very large datasets, consider:
  - Soft delete pattern (add `deleted_at` column instead of physical deletion)
  - Background job processing for large deletions
  - Batch deletion with progress tracking

## 9. Implementation Steps

1. **Add `destroy` action to `TripsController`:**
   - Add method signature with `sig { void }` for Sorbet typing
   - Add `:destroy` to the `before_action :set_trip` filter (or create separate before_action)
   - Use `current_user.trips.find(params[:id])` to find and authorize trip
   - Handle `ActiveRecord::RecordNotFound` (automatically handled by `rescue_from` in ApplicationController)
   - Store result in `@trip` instance variable

2. **Implement Deletion Logic:**
   - Call `@trip.destroy` to delete the trip and all associated records
   - ActiveRecord's `dependent: :destroy` handles cascading deletion automatically
   - The `destroy` method returns `true` if successful, `false` if validation prevents deletion (unlikely for Trip model)

3. **Handle Success Response:**
   - For JSON: `render json: { message: "Trip deleted successfully" }, status: :ok`
   - For HTML: `redirect_to trips_path, notice: 'Trip deleted successfully'`
   - Use `respond_to` block to handle both formats

4. **Error Handling (automatic):**
   - `ActiveRecord::RecordNotFound` is automatically caught by `rescue_from` in ApplicationController
   - Returns 404 with "Resource not found" message
   - Other exceptions (database errors, etc.) should be caught and handled gracefully

5. **Update `before_action` Filter:**
   - Add `:destroy` to the `set_trip` before_action in TripsController
   - Ensure `set_trip` uses `current_user.trips.find(params[:id])` for authorization
   - Current implementation has `set_trip` only for `:show` and `:update`, need to add `:destroy`

6. **Route Verification:**
   - Verify route is defined in `config/routes.rb` (should already exist: `resources :trips` includes `:destroy`)
   - Route should map to `trips#destroy` with `:id` parameter
   - DELETE method should route to destroy action

7. **Testing Considerations:**
   - Test successful deletion (trip and all associations deleted)
   - Test 404 when trip doesn't exist
   - Test 404 when trip belongs to different user (authorization)
   - Test 401 when user not authenticated
   - Test that notes are deleted (verify count before/after)
   - Test that generated_plans are deleted (verify count before/after)
   - Test JSON response format matches API specification
   - Test HTML response redirects correctly
   - Test transaction rollback on deletion failure (if applicable)
   - Test that deletion doesn't affect other users' trips

8. **Error Handling Verification:**
   - Verify `rescue_from ActiveRecord::RecordNotFound` in ApplicationController handles 404s
   - Verify error response format matches `ErrorResponseDTO` structure
   - Verify logging occurs for errors

9. **Security Verification:**
   - Verify users can only delete their own trips
   - Verify proper authentication is required
   - Test that attempting to delete another user's trip returns 404 (not revealing trip existence)

10. **Cascading Deletion Verification:**
    - Verify that all notes are deleted when trip is deleted
    - Verify that all generated_plans are deleted when trip is deleted
    - Test with trip that has multiple notes and generated plans
    - Verify no orphaned records remain in database

### Notes on Implementation:

- The `rescue_from ActiveRecord::RecordNotFound` in `ApplicationController` will automatically catch any `RecordNotFound` exception raised by `find`
- Using `current_user.trips` ensures proper authorization - if the trip belongs to another user, ActiveRecord will raise `RecordNotFound` when it can't find the trip in the scoped collection
- The `dependent: :destroy` association configuration in the Trip model ensures cascading deletion - no manual deletion of associations needed
- Follow the existing pattern from other controller actions for consistency (error handling, response formats, etc.)
- For HTML responses, redirect to trips index page after successful deletion (Rails convention)
- The `destroy` method is preferred over `delete` because it runs callbacks and validations (though Trip model has no destroy callbacks that would prevent deletion)
- Consider adding confirmation dialogs for HTML deletion (can be handled in the view layer, not controller)