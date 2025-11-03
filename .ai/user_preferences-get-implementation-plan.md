# API Endpoint Implementation Plan: Get User Preferences

## 1. Endpoint Overview

The `GET /preferences` endpoint retrieves the current authenticated user's travel preferences. This is a singleton resource endpoint (one preference record per user) that supports both HTML and JSON response formats. The endpoint requires authentication via Devise session and returns the user's preferences if they exist, or a 404 error if preferences have not been created yet.

**Key Characteristics:**
- Singleton resource (one-to-one relationship: User → UserPreference)
- Read-only operation (no request body or parameters)
- Requires authentication
- Returns structured JSON response with UserPreferencesDTO
- Supports graceful handling of missing preferences (404)

## 2. Request Details

### HTTP Method
- `GET`

### URL Structure
- `/preferences`

### Parameters
- **Required:** None (authentication handled via Devise session cookie)
- **Optional:** None
- **Query Parameters:** None

### Request Body
- Not applicable (GET request)

### Headers
- **Content-Type:** Not required for GET requests
- **Accept:** `application/json` (for JSON response) or `text/html` (for HTML response)
- **Authentication:** Session cookie (handled by Devise)

## 3. Used Types

### DTOs
- **`DTOs::UserPreferencesDTO`** - Data Transfer Object for user preferences
  - Method: `from_model(preferences: UserPreference)` → `UserPreferencesDTO`
  - Serialization: `dto.serialize` → Returns hash with all preference fields
  - Fields: `id`, `user_id`, `budget`, `accommodation`, `activities`, `eating_habits`, `created_at`, `updated_at`

### Command Models
- **None required** - GET request has no input parameters

### Models
- **`UserPreference`** - ActiveRecord model representing user preferences
  - Association: `belongs_to :user`
  - Validations: Handled at model level (budget, accommodation, eating_habits enum validation, activities format validation)

### Enums
- **`Enums::Budget`** - Budget preference values (budget_conscious, standard, luxury)
- **`Enums::Accommodation`** - Accommodation preference values (hotel, airbnb, hostel, resort, camping)
- **`Enums::Activity`** - Activity preference values (outdoors, sightseeing, cultural, relaxation, adventure, nightlife, shopping)
- **`Enums::EatingHabit`** - Eating habit preference values (restaurants_only, self_prepared, mix)

## 4. Response Details

### Success Response (200 OK)

**JSON Format:**
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
    "updated_at": "2025-10-19T12:00:00Z"
  }
}
```

**HTML Format:**
- Renders `preferences/show.html.erb` view template (if implemented)
- Sets `@user_preferences` instance variable for the view

### Error Responses

**401 Unauthorized (Not Authenticated):**
- Handled automatically by Devise `before_action :authenticate_user!`
- JSON: Returns Devise's standard unauthorized response
- HTML: Redirects to sign-in page

**404 Not Found (Preferences Not Created):**
- User preferences record does not exist for the current user
- Custom error message per API specification
```json
{
  "error": "Preferences not found. Please create your preferences."
}
```

**500 Internal Server Error:**
- Unexpected server-side errors (database connection failure, etc.)
- Handled by `ApplicationController#handle_server_error` (if implemented) or Rails default error handling
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

### Request Processing Flow

```
1. HTTP Request (GET /preferences)
   ↓
2. Rails Router → PreferencesController#show (or index if using RESTful routing)
   ↓
3. before_action :authenticate_user! (Devise)
   - Checks for valid session cookie
   - Sets current_user if authenticated
   - Redirects/returns 401 if not authenticated
   ↓ (if authenticated)
4. Query user preferences scoped to current_user
   - current_user.user_preference
   - Returns nil if preferences don't exist
   ↓
5. Check if preferences exist
   - If nil → Return 404 with custom error message
   - If present → Continue to transformation
   ↓
6. Transform UserPreference model → UserPreferencesDTO
   - DTOs::UserPreferencesDTO.from_model(@user_preferences)
   ↓
7. Respond based on format:
   - JSON: render json: { preferences: dto.serialize }, status: :ok
   - HTML: render :show with @user_preferences instance variable
```

### Database Queries

**Primary Query:**
```ruby
current_user.user_preference
```

**Expected SQL (optimized):**
```sql
SELECT "user_preferences".* 
FROM "user_preferences" 
WHERE "user_preferences"."user_id" = ? 
LIMIT 1
```

**Query Characteristics:**
- Single query with index on `user_id` (unique index ensures fast lookup)
- No N+1 queries (direct association lookup)
- Returns `nil` if no preferences exist (no exception raised)

### External Service Interactions
None (pure database read operation)

## 6. Security Considerations

### Authentication
- **Devise Integration:** Use `before_action :authenticate_user!` to ensure user is signed in
- **Session-based:** Relies on Devise session cookie for authentication
- **Automatic handling:** Devise handles unauthenticated requests automatically (redirects HTML, returns 401 for JSON)

### Authorization
- **User Scoping:** CRITICAL - Always scope to `current_user.user_preference` to prevent unauthorized access to other users' preferences
- **Singleton Resource:** The one-to-one relationship (`has_one :user_preference`) ensures each user can only access their own preferences
- **No ID Parameter:** Since this is a singleton resource, there's no route parameter to manipulate, reducing attack surface
- **Automatic protection:** Using `current_user.user_preference` ensures that ActiveRecord automatically scopes to the authenticated user

### Data Validation
- **No Input Validation Required:** GET request has no parameters to validate
- **Output Validation:** Model-level validations ensure data integrity, but output is read-only
- **SQL Injection Protection:** ActiveRecord parameter binding prevents SQL injection
- **XSS Protection:** Rails automatically escapes JSON output, and HTML views use ERB escaping

### Potential Security Threats

1. **Unauthorized Access Attempts:**
   - **Threat:** User attempting to access another user's preferences by manipulating session or other means
   - **Mitigation:** Using `current_user.user_preference` ensures preferences are scoped to the authenticated user. There's no route parameter to manipulate, making unauthorized access impossible.

2. **Session Hijacking:**
   - **Threat:** Malicious user hijacking another user's session
   - **Mitigation:** Devise handles session security. Application should be served over HTTPS in production. Session cookies should be secure and httpOnly.

3. **Information Disclosure:**
   - **Threat:** Revealing whether preferences exist or not through timing attacks
   - **Mitigation:** 404 response should be consistent in timing. However, the API specification requires a specific error message for missing preferences, which is acceptable as it provides helpful guidance to the user.

4. **CSRF:**
   - **Protection:** Rails CSRF protection handles HTML form submissions. JSON API requests from authenticated sessions are typically exempt, but should verify CSRF token for state-changing operations. This is a GET request, so CSRF is not applicable.

## 7. Error Handling

### Error Scenarios and Handling

| Scenario | HTTP Status | Handler | Message | Logging |
|----------|-------------|---------|---------|---------|
| User not authenticated | 401 | Devise | Standard Devise unauthorized response | Devise logs |
| Preferences not found | 404 | Controller (manual check) | "Preferences not found. Please create your preferences." | Rails.logger.warn |
| Database connection error | 500 | Rails/ApplicationController | "An unexpected error occurred" | Rails.logger.error with backtrace |
| Unexpected server error | 500 | ApplicationController#handle_server_error | "An unexpected error occurred" | Rails.logger.error with backtrace |

### Error Response Format

**404 Not Found (Custom Message):**
```json
{
  "error": "Preferences not found. Please create your preferences."
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

### Error Logging Strategy
- **404 Not Found:** Log at `warn` level with context (user_id, controller, action)
- **500 Internal Server Error:** Log at `error` level with full exception message and backtrace
- **Authentication Failures:** Handled by Devise (no custom logging needed)

## 8. Performance Considerations

### Potential Bottlenecks
1. **Database Query:**
   - **Risk:** Low - Single indexed query on `user_id` (unique index ensures O(1) lookup)
   - **Optimization:** Already optimal with unique index on `user_id`

2. **DTO Serialization:**
   - **Risk:** Negligible - Simple struct serialization with minimal data
   - **Optimization:** No optimization needed

3. **Response Size:**
   - **Risk:** Negligible - Small JSON payload (single record with ~7 fields)
   - **Optimization:** No optimization needed

### Optimization Strategies
- **Database Indexing:** Already in place - unique index on `user_id` column ensures fast lookups
- **Caching:** Not necessary for this endpoint (frequently accessed but low data volume, singleton resource)
- **Eager Loading:** Not applicable (single association lookup)
- **Query Optimization:** Already optimal - uses ActiveRecord's `has_one` association which leverages the unique index

### Performance Metrics
- **Expected Query Time:** < 1ms (single indexed lookup)
- **Expected Response Time:** < 10ms (including serialization)
- **Database Load:** Minimal (single query per request)

## 9. Implementation Steps

### Step 1: Add Route
Add the preferences route to `config/routes.rb`:
```ruby
# Add after trips routes
resource :preferences, only: [:show]  # Singleton resource (no :id parameter)
```

### Step 2: Create PreferencesController
Create `app/controllers/preferences_controller.rb`:
- Inherit from `ApplicationController`
- Add `before_action :authenticate_user!`
- Implement `show` action
- Use `current_user.user_preference` to find preferences
- Handle nil case (404 with custom message)
- Transform to DTO and render JSON response
- Support HTML format (optional, for future view implementation)

### Step 3: Implement Show Action Logic
```ruby
def show
  @user_preferences = current_user.user_preference
  
  if @user_preferences.nil?
    # Return 404 with custom error message per API spec
    respond_to do |format|
      format.json do
        error_dto = DTOs::ErrorResponseDTO.single_error(
          'Preferences not found. Please create your preferences.'
        )
        render json: error_dto.serialize, status: :not_found
      end
      format.html do
        flash[:alert] = 'Preferences not found. Please create your preferences.'
        # Redirect or render appropriate view
      end
    end
    return
  end
  
  # Success: Transform and render
  respond_to do |format|
    format.json do
      dto = DTOs::UserPreferencesDTO.from_model(@user_preferences)
      render json: { preferences: dto.serialize }, status: :ok
    end
    format.html { render :show }
  end
end
```

### Step 4: Add Error Handling (Optional Enhancement)
If needed, add custom error handling for database errors:
```ruby
rescue_from ActiveRecord::StatementInvalid, with: :handle_database_error
```

### Step 5: Add Sorbet Type Signatures
Add type signatures following existing patterns:
```ruby
# typed: strict
# frozen_string_literal: true

class PreferencesController < ApplicationController
  extend T::Sig
  
  sig { void }
  def show
    # ... implementation
  end
end
```

### Step 6: Create HTML View (Optional)
If HTML format is needed, create `app/views/preferences/show.html.erb`:
- Display user preferences in a readable format
- Use Tailwind CSS for styling
- Follow existing view patterns from trips views

### Step 7: Write Tests
Create `spec/requests/preferences_spec.rb`:
- Test successful retrieval (200 OK)
- Test missing preferences (404 Not Found)
- Test unauthenticated access (401 Unauthorized)
- Test JSON response format
- Test HTML response format (if implemented)

### Step 8: Verify Implementation
- Test endpoint manually using curl or Postman
- Verify JSON response structure matches API specification
- Verify error responses match API specification
- Check logs for proper error logging
- Verify authentication is required

## 10. Testing Strategy

### Unit Tests
- Test controller action logic
- Test DTO transformation
- Test error handling paths

### Integration Tests
- Test full request/response cycle
- Test authentication requirement
- Test 404 response for missing preferences
- Test JSON and HTML formats

### Test Cases

**Happy Path:**
```ruby
context 'when user has preferences' do
  let(:user) { create(:user) }
  let(:preferences) { create(:user_preference, user: user) }
  
  before { sign_in user }
  
  it 'returns 200 OK with preferences' do
    get '/preferences', as: :json
    expect(response).to have_http_status(:ok)
    expect(json['preferences']).to include(
      'id' => preferences.id,
      'user_id' => user.id,
      'budget' => preferences.budget
    )
  end
end
```

**Missing Preferences:**
```ruby
context 'when user has no preferences' do
  let(:user) { create(:user) }
  
  before { sign_in user }
  
  it 'returns 404 with error message' do
    get '/preferences', as: :json
    expect(response).to have_http_status(:not_found)
    expect(json['error']).to eq('Preferences not found. Please create your preferences.')
  end
end
```

**Unauthenticated:**
```ruby
context 'when user is not authenticated' do
  it 'returns 401 Unauthorized' do
    get '/preferences', as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
```

## 11. Additional Notes

### Design Decisions

1. **Singleton Resource Pattern:**
   - Using `resource :preferences` (singular) instead of `resources :preferences` (plural)
   - No `:id` parameter needed since each user has only one preference record
   - Route automatically maps to `show` action

2. **Error Message Customization:**
   - API specification requires specific error message: "Preferences not found. Please create your preferences."
   - This differs from the generic `handle_not_found` in ApplicationController
   - Manual check in controller action is necessary to provide custom message

3. **No Service Object:**
   - Simple read operation doesn't require service object abstraction
   - Follows Rails convention of keeping simple CRUD in controllers
   - Service objects are reserved for complex business logic

4. **HTML Format Support:**
   - Included for consistency with other endpoints
   - May be useful for future UI implementation
   - Can be implemented later if not immediately needed

### Future Considerations

1. **Caching:**
   - If preferences are accessed frequently, consider fragment caching
   - Since preferences are user-specific and change infrequently, caching could improve performance
   - Implementation: `cache_key_for_preferences` helper method

2. **Versioning:**
   - If API versioning is introduced, this endpoint should be included in versioned namespace
   - Current implementation assumes no versioning

3. **Rate Limiting:**
   - Consider rate limiting for API endpoints
   - Should be implemented at application/infrastructure level
   - Not specific to this endpoint

4. **Request Logging:**
   - Consider logging preferences access for analytics
   - Should be implemented at middleware level, not in controller
   - Useful for understanding user behavior

