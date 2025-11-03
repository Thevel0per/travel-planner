# API Endpoint Implementation Plan: Create/Update User Preferences

## 1. Endpoint Overview

The Create/Update User Preferences endpoint implements an upsert operation that allows authenticated users to create or update their travel preferences in a single endpoint. This is a singleton resource (one preference record per user) that supports partial updates, meaning users can update individual preference fields without providing all fields.

**Key Features:**
- Upsert operation: Creates preferences if they don't exist, updates them if they do
- Partial updates: All fields are optional, allowing incremental preference updates
- Authentication required: Only authenticated users can manage their own preferences
- Validation: Enforces enum values and validates activity lists

**Endpoint Details:**
- **HTTP Method:** `PUT` or `PATCH`
- **Path:** `/preferences`
- **Authentication:** Required (Devise session)
- **Response Format:** JSON (primary), HTML (optional)

## 2. Request Details

### HTTP Method
- `PUT` or `PATCH` (Rails convention supports both)

### URL Structure
```
PUT /preferences
PATCH /preferences
```

### Parameters

**Required:**
- Authentication: User must be authenticated via Devise session (`current_user` must exist)

**Optional (all preference fields are optional for partial updates):**
- `preferences[budget]` (String): One of `'budget_conscious'`, `'standard'`, `'luxury'`
- `preferences[accommodation]` (String): One of `'hotel'`, `'airbnb'`, `'hostel'`, `'resort'`, `'camping'`
- `preferences[activities]` (String): Comma-separated list of activities from: `'outdoors'`, `'sightseeing'`, `'cultural'`, `'relaxation'`, `'adventure'`, `'nightlife'`, `'shopping'`
- `preferences[eating_habits]` (String): One of `'restaurants_only'`, `'self_prepared'`, `'mix'`

### Request Body

**Structure:**
```json
{
  "preferences": {
    "budget": "standard",
    "accommodation": "hotel",
    "activities": "cultural,sightseeing",
    "eating_habits": "mix"
  }
}
```

**Notes:**
- The `preferences` key wraps all preference fields (nested format)
- All fields within `preferences` are optional
- Empty request body is allowed (no-op update)
- Partial updates are supported (only provide fields you want to update)

## 3. Used Types

### Command Model
- **`Commands::PreferencesUpdateCommand`** (already exists)
  - Purpose: Parses and validates request parameters
  - Location: `app/types/commands/preferences_update_command.rb`
  - Fields: All optional (budget, accommodation, activities, eating_habits)
  - Methods:
    - `from_params(params)`: Parses nested or flat parameter format
    - `to_model_attributes`: Converts command to hash for ActiveRecord

### DTO (Data Transfer Object)
- **`DTOs::UserPreferencesDTO`** (already exists)
  - Purpose: Serializes user preferences for API responses
  - Location: `app/types/dtos/user_preferences_dto.rb`
  - Factory method: `from_model(preferences)` converts UserPreference model to DTO

### Error Response DTO
- **`DTOs::ErrorResponseDTO`** (already exists)
  - Purpose: Standardized error response format
  - Factory methods:
    - `from_model_errors(model)`: Converts ActiveRecord validation errors
    - `single_error(message)`: Creates single error message response

### Enums (for validation)
- **`Enums::Budget`**: Valid values: `'budget_conscious'`, `'standard'`, `'luxury'`
- **`Enums::Accommodation`**: Valid values: `'hotel'`, `'airbnb'`, `'hostel'`, `'resort'`, `'camping'`
- **`Enums::Activity`**: Valid values: `'outdoors'`, `'sightseeing'`, `'cultural'`, `'relaxation'`, `'adventure'`, `'nightlife'`, `'shopping'`
- **`Enums::EatingHabit`**: Valid values: `'restaurants_only'`, `'self_prepared'`, `'mix'`

## 4. Response Details

### Success Response (200 OK)

**When:** Preferences are successfully created or updated

**Response Body:**
```json
{
  "preferences": {
    "id": 1,
    "user_id": 1,
    "budget": "standard",
    "accommodation": "hotel",
    "activities": "cultural,sightseeing",
    "eating_habits": "mix",
    "created_at": "2025-10-19T12:00:00Z",
    "updated_at": "2025-10-19T14:00:00Z"
  }
}
```

**Status Code:** `200 OK` (for both create and update operations)

**Notes:**
- Same response format for both create and update
- Timestamps in ISO 8601 format
- All fields included even if not provided in request (existing values preserved)

### Error Responses

#### 422 Unprocessable Content - Validation Errors

**When:** Invalid preference values provided

**Response Body:**
```json
{
  "errors": {
    "budget": ["is not included in the list"],
    "activities": ["contains invalid values"]
  }
}
```

**Status Code:** `422 Unprocessable Content`

**Common Validation Errors:**
- Invalid `budget` value (not in enum)
- Invalid `accommodation` value (not in enum)
- Invalid `eating_habits` value (not in enum)
- Invalid `activities` values (contains values not in enum list)
- Activities format issues (though comma-separated string is accepted)

#### 401 Unauthorized

**When:** User is not authenticated

**Response Body:**
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

**Status Code:** `401 Unauthorized`

**Handling:** Automatically handled by Devise via `authenticate_user!` before_action

#### 400 Bad Request

**When:** Malformed request (e.g., invalid JSON, missing preferences key structure)

**Response Body:**
```json
{
  "error": "Invalid request format"
}
```

**Status Code:** `400 Bad Request`

**Note:** Empty request body is allowed (no-op update), so 400 should only be returned for truly malformed requests.

#### 500 Internal Server Error

**When:** Unexpected server-side errors (database failures, etc.)

**Response Body:**
```json
{
  "error": "An unexpected error occurred"
}
```

**Status Code:** `500 Internal Server Error`

## 5. Data Flow

### Request Processing Flow

```
1. HTTP Request (PUT/PATCH /preferences with JSON body)
   ↓
2. Rails Router → PreferencesController#update
   ↓
3. before_action :authenticate_user! (Devise)
   ↓ (if authenticated)
4. Parse request parameters using PreferencesUpdateCommand
   - command = Commands::PreferencesUpdateCommand.from_params(params.permit!.to_h)
   ↓
5. Convert command to model attributes
   - attributes = command.to_model_attributes
   ↓
6. Find or initialize user preferences (upsert pattern)
   - user_preference = current_user.user_preference || current_user.build_user_preference
   - OR: user_preference = current_user.user_preference || UserPreference.new(user: current_user)
   ↓
7. Update preferences with attributes
   - user_preference.assign_attributes(attributes)
   - user_preference.save (activates model validations)
   ↓
8. Check if save succeeded:
   - If successful: Transform UserPreference model → UserPreferencesDTO
   - If validation failed: Transform errors → ErrorResponseDTO
   ↓
9. Respond based on format:
   - JSON: render json: { preferences: dto.serialize }, status: :ok (or 422)
   - HTML: redirect with flash message (or re-render with errors)
```

### Database Operations

**Upsert Pattern:**
```ruby
# Option 1: Using find_or_initialize_by (recommended)
user_preference = current_user.user_preference || current_user.build_user_preference

# Option 2: Using find_or_create_by (alternative)
user_preference = current_user.user_preference || current_user.create_user_preference
```

**Expected SQL for Find:**
```sql
SELECT "user_preferences".* FROM "user_preferences" 
WHERE "user_preferences"."user_id" = ? 
LIMIT 1
```

**Expected SQL for Create (if not exists):**
```sql
INSERT INTO "user_preferences" ("user_id", "budget", "accommodation", "activities", "eating_habits", "created_at", "updated_at")
VALUES (?, ?, ?, ?, ?, ?, ?)
```

**Expected SQL for Update (if exists):**
```sql
UPDATE "user_preferences" 
SET "budget" = ?, "accommodation" = ?, "activities" = ?, "eating_habits" = ?, "updated_at" = ? 
WHERE "user_preferences"."id" = ?
```

### Model Validations

The `UserPreference` model automatically validates:
1. **budget**: Must be in `Enums::Budget.string_values` (if present)
2. **accommodation**: Must be in `Enums::Accommodation.string_values` (if present)
3. **eating_habits**: Must be in `Enums::EatingHabit.string_values` (if present)
4. **activities**: Custom validation ensures all values in comma-separated list are valid `Enums::Activity.string_values`
5. **user_id**: Uniqueness constraint (enforced at database level)

## 6. Security Considerations

### Authentication
- **Requirement:** All requests must be authenticated via Devise session
- **Implementation:** `before_action :authenticate_user!` in `PreferencesController`
- **Unauthorized Access:** Returns 401 Unauthorized if user is not authenticated
- **Session Management:** Handled by Devise (automatic session expiration, CSRF protection)

### Authorization
- **User Isolation:** Users can only manage their own preferences
- **Implementation:** 
  - Use `current_user.user_preference` to ensure preferences belong to authenticated user
  - No need for explicit authorization check (user_id is set automatically from current_user)
- **Data Isolation:** Database foreign key constraint ensures preferences are tied to correct user

### Input Validation
- **Enum Validation:** All preference values validated against enum definitions
- **Type Validation:** String types enforced by command model
- **Activity List Validation:** Comma-separated activities validated individually
- **SQL Injection Protection:** ActiveRecord parameterized queries prevent SQL injection
- **XSS Protection:** Rails automatically escapes JSON output (no HTML rendering for JSON)

### Parameter Filtering
- **Strong Parameters:** Use `params.permit!` or explicit permit for nested preferences
- **Command Object:** `PreferencesUpdateCommand.from_params` handles parameter extraction safely
- **Whitelist Approach:** Only allowed fields can be updated (command model enforces this)

### Data Integrity
- **Uniqueness Constraint:** Database index on `user_id` ensures one preference per user
- **Foreign Key Constraint:** `user_preferences.user_id` references `users.id` (prevents orphaned records)
- **Transaction Safety:** ActiveRecord wraps save operations in transactions

### Security Threats and Mitigations

1. **Unauthorized Access:**
   - **Threat:** Unauthenticated users accessing preferences
   - **Mitigation:** `authenticate_user!` before_action

2. **User Impersonation:**
   - **Threat:** User updating another user's preferences
   - **Mitigation:** Always use `current_user.user_preference` (never accept user_id from params)

3. **Invalid Enum Values:**
   - **Threat:** Malicious or invalid enum values causing issues
   - **Mitigation:** Model validations enforce enum inclusion

4. **Mass Assignment:**
   - **Threat:** Updating fields not intended for user modification (e.g., id, user_id, timestamps)
   - **Mitigation:** Command model's `to_model_attributes` only includes allowed fields

5. **CSRF Attacks:**
   - **Threat:** Cross-site request forgery
   - **Mitigation:** Rails CSRF protection (automatic for HTML forms, token required for AJAX)

6. **SQL Injection:**
   - **Threat:** Malicious SQL in input parameters
   - **Mitigation:** ActiveRecord parameterized queries

## 7. Error Handling

### Validation Errors (422 Unprocessable Content)

**Triggered When:**
- Invalid `budget` value (not in enum: `'budget_conscious'`, `'standard'`, `'luxury'`)
- Invalid `accommodation` value (not in enum)
- Invalid `eating_habits` value (not in enum)
- Invalid `activities` values (contains values not in Activity enum)
- Activities format issues (though comma-separated string is accepted)

**Error Format:**
```json
{
  "errors": {
    "budget": ["is not included in the list"],
    "activities": ["contains invalid values: invalid_activity"]
  }
}
```

**Implementation:**
- Use `ErrorResponseDTO.from_model_errors(user_preference)` to convert ActiveRecord errors
- Status code: `422` (Rails `:unprocessable_content` symbol)
- Do not log validation errors as warnings (they are expected user input issues)

**Example Scenarios:**
- `budget: "premium"` → `{ "errors": { "budget": ["is not included in the list"] } }`
- `activities: "invalid,outdoors"` → `{ "errors": { "activities": ["contains invalid values: invalid"] } }`

### Authentication Errors (401 Unauthorized)

**Triggered When:**
- User session expired or invalid
- User not logged in
- Devise authentication fails

**Handling:**
- Devise handles automatically via `authenticate_user!` before_action
- For JSON requests, Devise may need configuration to return JSON error instead of redirect
- Status code: `401 Unauthorized`

### Bad Request (400 Bad Request)

**Triggered When:**
- Malformed JSON in request body
- Invalid parameter structure (e.g., preferences not nested correctly)

**Error Format:**
```json
{
  "error": "Invalid request format"
}
```

**Implementation:**
- Can use `rescue_from ActionController::ParameterMissing` in ApplicationController (already exists)
- Or manually check request format in controller
- Status code: `400 Bad Request`

**Note:** Empty request body is allowed (no-op update), so 400 should only be returned for truly malformed requests.

### Not Found (404 Not Found)

**Not Applicable:** This endpoint implements an upsert operation, so 404 is not used. The endpoint will create preferences if they don't exist.

### Server Errors (500 Internal Server Error)

**Triggered When:**
- Database connection failures
- Unexpected exceptions during save operation
- Foreign key constraint violations (though should be prevented by setting user_id correctly)
- Unique constraint violations (though should be prevented by upsert pattern)

**Error Format:**
```json
{
  "error": "An unexpected error occurred"
}
```

**Implementation:**
- Use `rescue_from StandardError` in ApplicationController (if implemented)
- Or wrap in `begin/rescue` block in controller
- Log full exception details to `Rails.logger.error`
- Return generic error message to client (do not expose internal details)
- Status code: `500 Internal Server Error`

### Error Logging Strategy

**Validation Errors:**
- Do not log (expected user input issues)
- Only log if validation logic itself has issues

**Authentication Errors:**
- Logged by Devise automatically
- May log at `warn` level for security monitoring

**Server Errors:**
- Log full exception with `Rails.logger.error`
- Include stack trace for debugging
- Do not expose details to client

## 8. Performance Considerations

### Database Operations

**Primary Query (find existing preferences):**
```ruby
current_user.user_preference
```

**Expected SQL:**
```sql
SELECT "user_preferences".* FROM "user_preferences" 
WHERE "user_preferences"."user_id" = ? 
LIMIT 1
```

**Performance:**
- Indexed query on `user_id` (unique index ensures fast lookup)
- Single record operation (O(1) lookup)
- No performance concerns

**Upsert Operation:**
- If preferences exist: Single UPDATE query
- If preferences don't exist: Single INSERT query
- Both operations are very fast (single record operations)

### No Performance Issues Expected

- Single record operation is very fast
- Indexed foreign key lookup (user_id)
- Minimal response payload
- No N+1 queries (not loading associations)
- No external service calls
- No complex calculations

### Optimization Notes

- **Database Index:** `user_id` unique index already exists (optimal for lookup)
- **Query Optimization:** Using `current_user.user_preference` leverages Rails association caching
- **Response Size:** Minimal JSON payload (7 fields)
- **Validation Performance:** Enum validations are in-memory array lookups (very fast)

## 9. Implementation Steps

1. **Add `update` action to `PreferencesController`:**
   - Add method signature with `sig { void }` for Sorbet typing
   - Action should be called `update` (Rails convention)
   - Handle both create and update scenarios (upsert pattern)

2. **Parse Request Parameters:**
   - Use `Commands::PreferencesUpdateCommand.from_params(params.permit!.to_h)` to parse request body
   - Command handles both nested (`params[:preferences]`) and flat parameter formats
   - All fields are optional (partial updates supported)

3. **Convert Command to Model Attributes:**
   - Call `command.to_model_attributes` to get hash of attributes to update
   - This method only includes provided fields (nil values are excluded)

4. **Implement Upsert Pattern:**
   - Find existing preferences: `current_user.user_preference`
   - If not found, initialize new: `current_user.build_user_preference` or `UserPreference.new(user: current_user)`
   - Assign attributes: `user_preference.assign_attributes(attributes)`
   - Save: `user_preference.save` (activates model validations)

5. **Handle Success Response:**
   - Transform updated/created preferences to DTO: `DTOs::UserPreferencesDTO.from_model(user_preference)`
   - Render JSON response: `render json: { preferences: dto.serialize }, status: :ok`
   - For HTML format: Redirect with success flash message (optional)

6. **Handle Validation Errors:**
   - Check `user_preference.errors.any?` after save attempt
   - Transform errors: `DTOs::ErrorResponseDTO.from_model_errors(user_preference)`
   - Render JSON response: `render json: error_dto.serialize, status: :unprocessable_content`
   - For HTML format: Re-render form with errors (optional)

7. **Add Update Route:**
   - Update `config/routes.rb` to include `:update` in the `preferences` singleton resource
   - Route should be: `resource :preferences, only: [:show, :update]`
   - This creates both `PUT /preferences` and `PATCH /preferences` routes

8. **Handle Edge Cases:**
   - Empty request body: Allow as no-op (return 200 with existing preferences)
   - All nil values: Allow (clears preferences, though might want to validate at least one field)
   - Malformed JSON: Let Rails handle (returns 400 automatically)

9. **Add Error Handling:**
   - Wrap save operation in `begin/rescue` if needed for unexpected errors
   - Use existing `ApplicationController` error handlers where applicable
   - Ensure proper error logging for server errors

10. **Test Implementation:**
    - Test creating new preferences (when user has none)
    - Test updating existing preferences (partial update)
    - Test validation errors (invalid enum values)
    - Test authentication (401 when not logged in)
    - Test empty request body (no-op update)

### Code Structure Example

```ruby
# app/controllers/preferences_controller.rb

def update
  # Parse request parameters using command object
  command = Commands::PreferencesUpdateCommand.from_params(params.permit!.to_h)
  attributes = command.to_model_attributes

  # Find or initialize user preferences (upsert pattern)
  user_preference = current_user.user_preference || current_user.build_user_preference
  user_preference.assign_attributes(attributes)

  # Save (activates model validations)
  if user_preference.save
    # Success: Return 200 OK with preferences DTO
    respond_to do |format|
      format.json do
        dto = DTOs::UserPreferencesDTO.from_model(user_preference)
        render json: { preferences: dto.serialize }, status: :ok
      end
      format.html do
        flash[:notice] = 'Preferences updated successfully'
        redirect_to preferences_path
      end
    end
  else
    # Validation failure: Return 422 Unprocessable Entity with error details
    respond_to do |format|
      format.json do
        error_dto = DTOs::ErrorResponseDTO.from_model_errors(user_preference)
        render json: error_dto.serialize, status: :unprocessable_content
      end
      format.html do
        # HTML view not implemented yet per requirements
        redirect_to preferences_path
      end
    end
  end
end
```

### Route Configuration

```ruby
# config/routes.rb

# User preferences - singleton resource (one preference per user)
resource :preferences, only: [:show, :update]
```

This creates:
- `GET /preferences` → `PreferencesController#show`
- `PUT /preferences` → `PreferencesController#update`
- `PATCH /preferences` → `PreferencesController#update`

