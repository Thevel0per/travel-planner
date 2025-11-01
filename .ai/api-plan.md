# REST API Plan - TravelPlanner

> **Note:** This is a fullstack Ruby on Rails application using Hotwire (Turbo + Stimulus) for the frontend, not a standalone REST API. The application uses standard Rails conventions with session-based authentication via Devise. Endpoints support both HTML and JSON formats for flexibility.

## 1. Resources

The API is organized around the following main resources:

| Resource | Database Table | Description |
|----------|---------------|-------------|
| Authentication | users | User registration, login, logout, password management, email verification (handled by devise) |
| Trips | trips | User's travel trips with destination, dates, and group size |
| Notes | notes | Text notes associated with specific trips |
| Preferences | user_preferences | User's travel preferences (singleton resource per user) |
| Generated Plans | generated_plans | AI-generated travel plans for trips |

## 2. Endpoints

### 2.1. Trip Endpoints

#### List Trips
- **Method:** `GET`
- **Path:** `/trips`
- **Description:** Retrieve all trips for authenticated user
- **Authentication:** Required (Devise session)
- **Query Parameters:**
  - `page` (optional, default: 1): Page number for pagination
  - `per_page` (optional, default: 20, max: 100): Items per page
  - `sort_by` (optional, default: start_date): Field to sort by (start_date, created_at, destination)
  - `sort_order` (optional, default: asc): Sort order (asc, desc)
  - `destination` (optional): Filter by destination (partial match)
- **Success Response (200 OK):**
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
      "updated_at": "2025-10-19T12:00:00Z",
      "notes_count": 5,
      "generated_plans_count": 2
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

#### Create Trip
- **Method:** `POST`
- **Path:** `/trips`
- **Description:** Create a new trip
- **Authentication:** Required (Devise session)
- **Request Payload:**
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
- **Success Response (201 Created):**
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
- **Error Responses:**
  - `422 Unprocessable Content`: Validation errors
    ```json
    {
      "errors": {
        "name": ["can't be blank"],
        "end_date": ["must be after start date"],
        "number_of_people": ["must be greater than 0"]
      }
    }
    ```

#### Get Trip
- **Method:** `GET`
- **Path:** `/trips/:id`
- **Description:** Retrieve a specific trip with its notes and generated plans
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
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
        "content": "Visit Eiffel Tower",
        "created_at": "2025-10-19T12:00:00Z",
        "updated_at": "2025-10-19T12:00:00Z"
      }
    ],
    "generated_plans": [
      {
        "id": 1,
        "status": "completed",
        "rating": 8,
        "created_at": "2025-10-19T12:00:00Z",
        "updated_at": "2025-10-19T12:00:00Z"
      }
    ]
  }
}
```
- **Error Responses:**
  - `404 Not Found`: Trip not found or doesn't belong to user
    ```json
    {
      "error": "Trip not found"
    }
    ```

#### Update Trip
- **Method:** `PUT/PATCH`
- **Path:** `/trips/:id`
- **Description:** Update an existing trip
- **Authentication:** Required (Devise session)
- **Request Payload:**
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
- **Success Response (200 OK):**
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
- **Error Responses:**
  - `404 Not Found`: Trip not found
  - `422 Unprocessable Content`: Validation errors

#### Delete Trip
- **Method:** `DELETE`
- **Path:** `/trips/:id`
- **Description:** Delete a trip and all associated notes and generated plans
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
```json
{
  "message": "Trip deleted successfully"
}
```
- **Error Responses:**
  - `404 Not Found`: Trip not found
    ```json
    {
      "error": "Trip not found"
    }
    ```

### 2.2. Note Endpoints

#### List Notes for Trip
- **Method:** `GET`
- **Path:** `/trips/:trip_id/notes`
- **Description:** Retrieve all notes for a specific trip
- **Authentication:** Required (Devise session)
- **Query Parameters:**
  - `page` (optional, default: 1): Page number
  - `per_page` (optional, default: 50, max: 100): Items per page
- **Success Response (200 OK):**
```json
{
  "notes": [
    {
      "id": 1,
      "trip_id": 1,
      "content": "Visit Eiffel Tower at sunset",
      "created_at": "2025-10-19T12:00:00Z",
      "updated_at": "2025-10-19T12:00:00Z"
    },
    {
      "id": 2,
      "trip_id": 1,
      "content": "Try authentic French croissants",
      "created_at": "2025-10-19T12:30:00Z",
      "updated_at": "2025-10-19T12:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 2,
    "per_page": 50
  }
}
```
- **Error Responses:**
  - `404 Not Found`: Trip not found or doesn't belong to user

#### Create Note
- **Method:** `POST`
- **Path:** `/trips/:trip_id/notes`
- **Description:** Add a new note to a trip
- **Authentication:** Required (Devise session)
- **Request Payload:**
```json
{
  "note": {
    "content": "Visit Louvre Museum"
  }
}
```
- **Success Response (201 Created):**
```json
{
  "note": {
    "id": 3,
    "trip_id": 1,
    "content": "Visit Louvre Museum",
    "created_at": "2025-10-19T13:00:00Z",
    "updated_at": "2025-10-19T13:00:00Z"
  }
}
```
- **Error Responses:**
  - `404 Not Found`: Trip not found
  - `422 Unprocessable Content`: Validation errors
    ```json
    {
      "errors": {
        "content": ["can't be blank"]
      }
    }
    ```

#### Get Note
- **Method:** `GET`
- **Path:** `/trips/:trip_id/notes/:id`
- **Description:** Retrieve a specific note
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
```json
{
  "note": {
    "id": 1,
    "trip_id": 1,
    "content": "Visit Eiffel Tower at sunset",
    "created_at": "2025-10-19T12:00:00Z",
    "updated_at": "2025-10-19T12:00:00Z"
  }
}
```
- **Error Responses:**
  - `404 Not Found`: Note or trip not found

#### Update Note
- **Method:** `PUT/PATCH`
- **Path:** `/trips/:trip_id/notes/:id`
- **Description:** Update an existing note
- **Authentication:** Required (Devise session)
- **Request Payload:**
```json
{
  "note": {
    "content": "Visit Eiffel Tower at sunset - book tickets in advance"
  }
}
```
- **Success Response (200 OK):**
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
- **Error Responses:**
  - `404 Not Found`: Note not found
  - `422 Unprocessable Content`: Validation errors

#### Delete Note
- **Method:** `DELETE`
- **Path:** `/trips/:trip_id/notes/:id`
- **Description:** Delete a note
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
```json
{
  "message": "Note deleted successfully"
}
```
- **Error Responses:**
  - `404 Not Found`: Note not found

### 2.3. User Preferences Endpoints

#### Get Preference Options
- **Method:** `GET`
- **Path:** `/preferences/options`
- **Description:** Retrieve available options for each preference category
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
```json
{
  "options": {
    "budget": [
      "budget_conscious",
      "standard",
      "luxury"
    ],
    "accommodation": [
      "hotel",
      "airbnb",
      "hostel",
      "resort",
      "camping"
    ],
    "activities": [
      "outdoors",
      "sightseeing",
      "cultural",
      "relaxation",
      "adventure",
      "nightlife",
      "shopping"
    ],
    "eating_habits": [
      "restaurants_only",
      "self_prepared",
      "mix"
    ]
  }
}
```

#### Get User Preferences
- **Method:** `GET`
- **Path:** `/preferences`
- **Description:** Retrieve current user's travel preferences
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
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
- **Error Responses:**
  - `404 Not Found`: Preferences not yet created
    ```json
    {
      "error": "Preferences not found. Please create your preferences."
    }
    ```

#### Create/Update User Preferences
- **Method:** `PUT/PATCH`
- **Path:** `/preferences`
- **Description:** Create or update user's travel preferences (upsert operation)
- **Authentication:** Required (Devise session)
- **Request Payload:**
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
- **Success Response (200 OK):**
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
- **Error Responses:**
  - `422 Unprocessable Content`: Invalid preference values
    ```json
    {
      "errors": {
        "budget": ["is not included in the list"],
        "activities": ["contains invalid values"]
      }
    }
    ```

### 2.4. Generated Plan Endpoints

#### List Generated Plans for Trip
- **Method:** `GET`
- **Path:** `/trips/:trip_id/generated_plans`
- **Description:** Retrieve all generated plans for a specific trip
- **Authentication:** Required (Devise session)
- **Query Parameters:**
  - `status` (optional): Filter by status (pending, generating, completed, failed)
  - `page` (optional, default: 1): Page number
  - `per_page` (optional, default: 10, max: 50): Items per page
- **Success Response (200 OK):**
```json
{
  "generated_plans": [
    {
      "id": 1,
      "trip_id": 1,
      "status": "completed",
      "rating": 8,
      "created_at": "2025-10-19T12:00:00Z",
      "updated_at": "2025-10-19T12:30:00Z",
      "content_preview": "Day 1: Arrival in Paris..."
    },
    {
      "id": 2,
      "trip_id": 1,
      "status": "generating",
      "rating": null,
      "created_at": "2025-10-19T14:00:00Z",
      "updated_at": "2025-10-19T14:00:00Z",
      "content_preview": null
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 2,
    "per_page": 10
  }
}
```
- **Error Responses:**
  - `404 Not Found`: Trip not found

#### Create Generated Plan (Initiate Generation)
- **Method:** `POST`
- **Path:** `/trips/:trip_id/generated_plans`
- **Description:** Initiate AI-powered travel plan generation for a trip
- **Authentication:** Required (Devise session)
- **Request Payload:** (optional, can be empty)
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
- **Success Response (202 Accepted):**
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
- **Error Responses:**
  - `404 Not Found`: Trip not found
  - `422 Unprocessable Content`: Missing required data
    ```json
    {
      "error": "Cannot generate plan without user preferences. Please set your preferences first."
    }
    ```
  - `429 Too Many Requests`: Rate limit exceeded
    ```json
    {
      "error": "Too many generation requests. Please wait before creating another plan."
    }
    ```

#### Get Generated Plan
- **Method:** `GET`
- **Path:** `/trips/:trip_id/generated_plans/:id`
- **Description:** Retrieve a specific generated plan with full content
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
```json
{
  "generated_plan": {
    "id": 1,
    "trip_id": 1,
    "status": "completed",
    "rating": 8,
    "content": {
      "summary": {
        "total_cost_usd": 3500.00,
        "cost_per_person_usd": 1750.00,
        "duration_days": 7,
        "number_of_people": 2
      },
      "daily_itinerary": [
        {
          "day": 1,
          "date": "2025-07-15",
          "activities": [
            {
              "time": "10:00 AM",
              "name": "Eiffel Tower Visit",
              "duration_minutes": 180,
              "estimated_cost_usd": 30.00,
              "estimated_cost_per_person_usd": 15.00,
              "rating": 4.8,
              "description": "Visit the iconic Eiffel Tower, including access to the second floor observation deck."
            }
          ],
          "restaurants": [
            {
              "meal": "lunch",
              "name": "Le Comptoir du Relais",
              "cuisine": "French",
              "estimated_cost_per_person_usd": 40.00,
              "rating": 4.5
            }
          ]
        }
      ]
    },
    "created_at": "2025-10-19T12:00:00Z",
    "updated_at": "2025-10-19T12:30:00Z"
  }
}
```
- **Error Responses:**
  - `404 Not Found`: Generated plan not found
  - `202 Accepted`: Plan still generating
    ```json
    {
      "generated_plan": {
        "id": 2,
        "trip_id": 1,
        "status": "generating",
        "rating": null,
        "created_at": "2025-10-19T14:00:00Z",
        "updated_at": "2025-10-19T14:00:00Z"
      },
      "message": "Plan is still being generated. Please try again shortly."
    }
    ```

#### Update Generated Plan (Rate Plan)
- **Method:** `PATCH`
- **Path:** `/trips/:trip_id/generated_plans/:id`
- **Description:** Update a generated plan (primarily for rating)
- **Authentication:** Required (Devise session)
- **Request Payload:**
```json
{
  "generated_plan": {
    "rating": 8
  }
}
```
- **Success Response (200 OK):**
```json
{
  "generated_plan": {
    "id": 1,
    "trip_id": 1,
    "status": "completed",
    "rating": 8,
    "created_at": "2025-10-19T12:00:00Z",
    "updated_at": "2025-10-19T15:00:00Z"
  },
  "message": "Rating saved successfully"
}
```
- **Error Responses:**
  - `404 Not Found`: Generated plan not found
  - `422 Unprocessable Content`: Invalid rating
    ```json
    {
      "errors": {
        "rating": ["must be between 1 and 10"]
      }
    }
    ```

#### Delete Generated Plan
- **Method:** `DELETE`
- **Path:** `/trips/:trip_id/generated_plans/:id`
- **Description:** Delete a generated plan
- **Authentication:** Required (Devise session)
- **Success Response (200 OK):**
```json
{
  "message": "Generated plan deleted successfully"
}
```
- **Error Responses:**
  - `404 Not Found`: Generated plan not found

## 3. Authentication and Authorization

### 3.1. Authentication Mechanism

**Session-Based Authentication using Devise**

The application uses standard Devise with cookie-based session authentication:

1. **Registration Flow:**
   - User registers via Devise's standard registration form
   - Confirmation email sent with unique token
   - User confirms via clicking link in email
   - Account activated

2. **Login Flow:**
   - User logs in via Devise's standard login form
   - Server validates credentials and email confirmation
   - Server creates session stored in encrypted cookie
   - Session cookie automatically included in subsequent requests

3. **Authenticated Requests:**
   - Browser automatically includes session cookie with each request
   - Rails/Devise validates session on each request
   - `current_user` helper available in controllers and views

4. **Logout Flow:**
   - User logs out via Devise's logout action
   - Server destroys session
   - Session cookie cleared from browser

### 3.2. Devise Configuration

- **Modules enabled:** `:database_authenticatable`, `:registerable`, `:recoverable`, `:rememberable`, `:validatable`, `:confirmable`
- **Password length:** 6-128 characters
- **Reset password token valid for:** 6 hours
- **Confirmation required:** Yes, users must confirm email before logging in
- **Remember me:** Enabled, tokens expire on sign out

### 3.3. Standard Devise Routes

The application uses Devise's standard routes (mounted at `/users`):

**Registration:**
- `GET /users/sign_up` - New user registration form
- `POST /users` - Create new user account

**Session Management:**
- `GET /users/sign_in` - Login form
- `POST /users/sign_in` - Authenticate user
- `DELETE /users/sign_out` - Logout

**Email Confirmation:**
- `GET /users/confirmation/new` - Resend confirmation instructions form
- `POST /users/confirmation` - Resend confirmation email
- `GET /users/confirmation?confirmation_token=...` - Confirm email

**Password Recovery:**
- `GET /users/password/new` - Forgot password form
- `POST /users/password` - Send password reset email
- `GET /users/password/edit?reset_password_token=...` - Reset password form
- `PUT /users/password` - Update password with token

**Account Management:**
- `GET /users/edit` - Edit account (email/password)
- `PUT /users` - Update account
- `DELETE /users` - Cancel account (if enabled)

### 3.4. Authorization Rules

**Resource-Level Authorization:**

1. **Trips:**
   - Users can only access trips where `trip.user_id == current_user.id`
   - All CRUD operations restricted to trip owner

2. **Notes:**
   - Users can only access notes belonging to their trips
   - Verified by checking `note.trip.user_id == current_user.id`

3. **User Preferences:**
   - Users can only access their own preferences
   - Singleton resource automatically scoped to `current_user`

4. **Generated Plans:**
   - Users can only access plans belonging to their trips
   - Verified by checking `generated_plan.trip.user_id == current_user.id`

**Implementation:**
- Authentication required via `before_action :authenticate_user!` in controllers
- Authorization checks performed in controllers before any database operations
- Use of Rails `before_action` filters to set and authorize resources
- Returns `404 Not Found` for unauthorized access (to prevent resource enumeration)

### 3.5. CSRF Protection

- **Enabled by default** for all non-GET requests in Rails
- CSRF token automatically included in forms via `form_with` helper
- Turbo automatically handles CSRF tokens for dynamic requests
- Token verified on every state-changing request

## 4. Validation and Business Logic

### 4.1. Validation Rules

#### Users (Devise)
- **email:**
  - Required
  - Must be valid email format
  - Must be unique (case-insensitive)
  
- **password:**
  - Required on registration
  - Length: 6-128 characters
  - Must match password_confirmation on registration

#### Trips
- **name:**
  - Required
  - Maximum 255 characters

- **destination:**
  - Required
  - Maximum 255 characters

- **start_date:**
  - Required
  - Must be a valid date

- **end_date:**
  - Required
  - Must be a valid date
  - Must be after start_date

- **number_of_people:**
  - Required
  - Must be a positive integer (> 0)
  - Default value: 1

- **user_id:**
  - Required (set automatically from authenticated user)
  - Must reference existing user

#### Notes
- **content:**
  - Required
  - Cannot be blank
  - Maximum 10,000 characters

- **trip_id:**
  - Required
  - Must reference existing trip
  - Trip must belong to authenticated user

#### User Preferences
- **budget:**
  - Optional
  - If provided, must be one of: `budget_conscious`, `standard`, `luxury`

- **accommodation:**
  - Optional
  - If provided, must be one of: `hotel`, `airbnb`, `hostel`, `resort`, `camping`

- **activities:**
  - Optional
  - Comma-separated string of multiple values
  - Each value must be one of: `outdoors`, `sightseeing`, `cultural`, `relaxation`, `adventure`, `nightlife`, `shopping`

- **eating_habits:**
  - Optional
  - If provided, must be one of: `restaurants_only`, `self_prepared`, `mix`

- **user_id:**
  - Required (set automatically from authenticated user)
  - Must be unique (one preference record per user)

#### Generated Plans
- **status:**
  - Required
  - Must be one of: `pending`, `generating`, `completed`, `failed`
  - Default: `pending`
  - Cannot be set by user directly (managed by system)

- **rating:**
  - Optional
  - If provided, must be integer between 1 and 10 (inclusive)
  - Can only be set after plan status is `completed`

- **content:**
  - Required when status is `completed`
  - JSON structure validated against expected schema

- **trip_id:**
  - Required
  - Must reference existing trip
  - Trip must belong to authenticated user

### 3.2. Business Logic Implementation

#### Trip Management
1. **Trip Creation:**
   - Automatically associates trip with authenticated user
   - Validates date range (end_date > start_date)
   - Sets default number_of_people to 1 if not provided

2. **Trip Deletion:**
   - Cascade deletes all associated notes
   - Cascade deletes all associated generated plans
   - Requires confirmation (handled at UI level)
   - Cannot be undone

3. **Trip Updates:**
   - All fields updatable except user_id
   - Date validation reapplied on update
   - Associated plans remain valid (regeneration not automatic)

#### Note Management
1. **Note Operations:**
   - Notes must belong to a valid trip owned by user
   - No restrictions on number of notes per trip
   - Notes returned in chronological order (created_at)

#### Preference Management
1. **Preference Upsert:**
   - Single preference record per user (one-to-one relationship)
   - PUT/PATCH creates if doesn't exist, updates if exists
   - Partial updates allowed (can update only specific fields)
   - Empty/null values allowed (user can "unset" preferences)

2. **Preference Usage:**
   - Used as input for AI plan generation
   - Not required to generate plans, but recommended
   - If no preferences set, API returns warning but allows generation

#### AI Plan Generation
1. **Generation Process:**
   - User initiates via POST request
   - System creates generated_plan record with status `pending`
   - Background job queued to process generation
   - Status updated to `generating` when job starts
   - Job calls OpenRouter API with GPT-4o-mini
   - Input includes: trip details, all trip notes, user preferences
   - Status updated to `completed` on success, `failed` on error
   - Content stored as JSON in database

2. **Generation Rate Limiting:**
   - Maximum 5 plan generations per user per hour
   - Maximum 50 plan generations per user per day
   - Prevents API abuse and controls costs

3. **Plan Regeneration:**
   - Users can generate multiple plans for same trip
   - Previous plans not deleted automatically
   - Each generation is independent

4. **Content Structure:**
   - JSON format with predefined schema
   - Includes: summary, daily_itinerary, activities, restaurants
   - Costs in USD, ratings for activities and restaurants
   - Validation against schema before saving

#### Rating System
1. **Plan Rating:**
   - Users can rate completed plans 1-10
   - Rating can be updated (user can change their rating)
   - Rating collected for analytics but not used in MVP for feedback loop
   - Plans without ratings show null for rating field

2. **Rating Analytics:**
   - Average ratings tracked per user (for future features)
   - No automatic adjustment of AI prompts based on ratings in MVP

### 3.3. Error Handling

**Error Responses:**

The application handles errors differently based on request format:

**HTML Responses:**
- Validation errors: Re-render form with error messages
- Authentication errors: Redirect to login page with flash message
- Authorization errors: Redirect or show 404 page
- Flash messages used for user feedback: `flash[:notice]`, `flash[:alert]`, `flash[:error]`

**JSON Responses:**
```json
{
  "error": "Error message for single error",
  "errors": {
    "field_name": ["error message 1", "error message 2"]
  }
}
```

**Turbo Responses:**
- Turbo Stream updates to show/hide error messages
- Can update specific parts of page without full reload

**HTTP Status Codes:**
- `200 OK`: Successful GET, PUT, PATCH, DELETE
- `201 Created`: Successful POST creating new resource
- `202 Accepted`: Request accepted but not yet processed (async operations)
- `302 Found` / `303 See Other`: Redirects (Rails 8 default for Turbo)
- `401 Unauthorized`: Not authenticated (redirects to login for HTML)
- `403 Forbidden`: Authenticated but not authorized
- `404 Not Found`: Resource not found or user not authorized
- `422 Unprocessable Content`: Validation errors (Rails default for form errors)
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Temporary service disruption

**Note:** Rails 8 with Hotwire/Turbo uses `422` for errors and `303` for redirects by default (configured in `devise.rb`).

### 3.4. Pagination

**Pagination Parameters:**
- `page`: Page number (default: 1, minimum: 1)
- `per_page`: Items per page (default varies by resource, maximum enforced)

**Pagination Metadata:**
```json
{
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 87,
    "per_page": 20
  }
}
```

**Default Limits:**
- Trips: 20 per page (max 100)
- Notes: 50 per page (max 100)
- Generated Plans: 10 per page (max 50)

### 3.5. Filtering and Sorting

**Trips Filtering:**
- `destination`: Partial text match (case-insensitive)

**Trips Sorting:**
- `sort_by`: `start_date`, `created_at`, `destination`, `name`
- `sort_order`: `asc`, `desc`
- Default: `start_date asc`

**Generated Plans Filtering:**
- `status`: Exact match on status field

### 3.6. Rate Limiting

**Plan Generation:**
- 5 generations per user per hour
- 50 generations per user per day
- Prevents API abuse and controls OpenRouter costs

**Implementation:**
- Tracked in application layer (controller or service object)
- Returns appropriate error message when limit exceeded
- Rate limits reset based on sliding time window

**Rate Limit Response (429):**
- Flash error message for HTML requests
- JSON error response for API requests:
```json
{
  "error": "Rate limit exceeded. You can generate up to 5 plans per hour. Please try again later."
}
```

**Future Considerations:**
- General request rate limiting can be added with Rack::Attack if needed
- Failed login attempt limiting handled by Devise (can enable `:lockable` module)


### 3.8. CORS Configuration

**Not Required for MVP:**
Since this is a fullstack Rails application (not a separate API), CORS configuration is not needed. The frontend and backend are served from the same domain.

**Future Considerations:**
If a separate mobile app or external API access is added later:
- Use `rack-cors` gem
- Configure allowed origins in environment variables
- Allow credentials for cookie-based authentication

### 3.9. Content Negotiation

**Response Formats:**
The application is a Rails fullstack app using Hotwire (Turbo + Stimulus), supporting multiple response formats:

- **HTML:** Primary format for page loads and Turbo Frame/Stream updates
- **JSON:** For AJAX requests and potential future API access
- **Turbo Stream:** For dynamic page updates without full reload

**Content Negotiation:**
- Rails automatically responds based on `Accept` header or request format
- Forms use `form_with` helper which defaults to Turbo-compatible requests
- JSON responses available by adding `.json` to URL or setting Accept header

**Response Envelopes:**
- HTML responses: Standard Rails views with layouts
- JSON responses: Resource data with appropriate structure
- Turbo Stream responses: Turbo-specific instructions for DOM updates

### 3.10. Timestamps

**Format:**
- ISO 8601 format: `YYYY-MM-DDTHH:MM:SSZ`
- UTC timezone
- Examples: `2025-10-19T12:00:00Z`

**Date-Only Fields:**
- Format: `YYYY-MM-DD`
- Examples: `2025-07-15`

### 3.11. Asynchronous Operations

**Generated Plans:**
- Creation returns `202 Accepted` with initial resource
- Client polls GET endpoint to check status
- Recommended polling interval: 5 seconds
- Maximum generation time: 2 minutes
- Timeout results in `failed` status

**Status Progression:**
- `pending` → `generating` → `completed` or `failed`
- Once `completed` or `failed`, status is final

**Webhooks (Future):**
- Not implemented in MVP
- Future feature: Optional webhook URL for completion notification

