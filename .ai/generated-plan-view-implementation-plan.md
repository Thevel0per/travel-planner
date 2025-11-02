# View Implementation Plan: Generated Plan View

## 1. Overview

The Generated Plan View displays a detailed, structured AI-generated travel plan for a specific trip. This view presents all plan information in a well-organized format, including activities with durations and costs, cost summaries (total and per-person), activity ratings, and restaurant suggestions. The view handles multiple plan states (pending, generating, completed, failed) and allows users to rate completed plans. The implementation follows Material Design principles via Material Tailwind CSS and uses Hotwire (Turbo and Stimulus) for dynamic updates.

**Key Features:**
- Display full generated plan content when status is 'completed'
- Show loading states for 'pending' and 'generating' statuses
- Display error state for 'failed' status
- Present all required elements: activities, durations, costs, cost summaries, ratings, restaurants
- Allow users to rate completed plans (1-10 scale)
- Real-time status updates via Turbo Streams
- Responsive design with mobile-first approach

## 2. View Routing

- **Path:** `/trips/:trip_id/generated_plans/:id`
- **HTTP Method:** `GET`
- **Controller Action:** `Trips::GeneratedPlansController#show`
- **Route Helper:** `trip_generated_plan_path(@trip, @generated_plan)` or `trip_generated_plan_path(trip_id: @trip.id, id: @generated_plan.id)`
- **Authentication:** Required (protected by `before_action :authenticate_user!`)
- **Authorization:** User can only view generated plans belonging to their trips (enforced by `current_user.trips.find(params[:trip_id])`)

**Note:** The route must be added to `config/routes.rb` in the nested resources block for `generated_plans` under `trips`.

## 3. Component Structure

The Generated Plan View is composed of reusable and view-specific components organized hierarchically:

```
app/views/trips/generated_plans/show.html.erb (Main Container)
├── render 'shared/page_header'
│   └── Title and optional description
├── PlanStatusBanner Partial (_plan_status_banner.html.erb)
│   ├── Status Chip (pending/generating/completed/failed)
│   ├── Status message
│   └── Loading indicator (if generating)
├── PlanContentSection Partial (_plan_content_section.html.erb) [Only when completed]
│   ├── PlanSummaryCard (_plan_summary_card.html.erb)
│   │   ├── Total Cost Display
│   │   ├── Cost Per Person Display
│   │   ├── Duration Display
│   │   └── Number of People Display
│   ├── DailyItinerarySection (_daily_itinerary_section.html.erb)
│   │   └── DailyItineraryDay Cards (iterated)
│   │       ├── Day Header (day number, date)
│   │       ├── ActivitiesList (_activities_list.html.erb)
│   │       │   └── ActivityItem Cards (iterated)
│   │       │       ├── Time Display
│   │       │       ├── Activity Name
│   │       │       ├── Duration Display
│   │       │       ├── Cost Display (total and per-person)
│   │       │       ├── Rating Display (star rating 0-5)
│   │       │       └── Description
│   │       └── RestaurantsList (_restaurants_list.html.erb)
│   │           └── RestaurantItem Cards (iterated)
│   │               ├── Meal Type Badge
│   │               ├── Restaurant Name
│   │               ├── Cuisine Type
│   │               ├── Cost Per Person Display
│   │               └── Rating Display (star rating 0-5)
│   └── PlanRatingSection (_plan_rating_section.html.erb)
│       ├── Current Rating Display (if rated)
│       └── RatingForm (_rating_form.html.erb)
│           ├── Rating Input (1-10 scale)
│           └── Submit Button
└── NavigationActions Partial (_navigation_actions.html.erb)
    ├── Back to Trip Link
    └── Delete Plan Button (optional, future feature)
```

**Reusable Component Locations:**
- `app/views/shared/_page_header.html.erb` - Generic page header component
- `app/views/trips/generated_plans/_plan_status_banner.html.erb` - Status display component
- `app/views/trips/generated_plans/_plan_content_section.html.erb` - Main content wrapper
- `app/views/trips/generated_plans/_plan_summary_card.html.erb` - Summary card component
- `app/views/trips/generated_plans/_daily_itinerary_section.html.erb` - Daily itinerary wrapper
- `app/views/trips/generated_plans/_daily_itinerary_day.html.erb` - Single day card
- `app/views/trips/generated_plans/_activities_list.html.erb` - Activities container
- `app/views/trips/generated_plans/_activity_item.html.erb` - Single activity card
- `app/views/trips/generated_plans/_restaurants_list.html.erb` - Restaurants container
- `app/views/trips/generated_plans/_restaurant_item.html.erb` - Single restaurant card
- `app/views/trips/generated_plans/_plan_rating_section.html.erb` - Rating section wrapper
- `app/views/trips/generated_plans/_rating_form.html.erb` - Rating form component

## 4. Component Details

### GeneratedPlanShowView (Main Container)

- **Component description:** The root container component that wraps the entire generated plan view. Provides consistent page structure and Material Design styling context using the `material-tailwind` Stimulus controller.

- **Main elements:**
  - `<div>` with `data-controller="material-tailwind"` attribute for Material Tailwind initialization
  - Container div with Material Design spacing and max-width constraints
  - Semantic `<main>` element containing the view content

- **Handled interactions:** None (container only)

- **Handled validation:** None (delegated to child components)

- **Types:** None (view-level component)

- **Props:** Receives `@generated_plan` (GeneratedPlanDetailDTO) and `@trip` (Trip model) from controller

### PageHeader (Reusable Component)

- **Component description:** A reusable component that displays page titles. Located at `app/views/shared/_page_header.html.erb`.

- **Main elements:**
  - `<h1>` element with Material Design typography classes

- **Handled interactions:** None

- **Handled validation:** None

- **Types:** None

- **Props:** `title` (String) - "Travel Plan Details"

### PlanStatusBanner

- **Component description:** Displays the current status of the generated plan with visual indicators. Shows different states: pending (gray), generating (blue with spinner), completed (green), failed (red). Provides user feedback about the plan generation process.

- **Main elements:**
  - Status Chip (Material Design Chip) with color-coded background
  - Status message text
  - Animated spinner icon (when status is 'generating')
  - Conditional messaging based on status

- **Handled interactions:** None (display only)

- **Handled validation:**
  - Validates that status is one of: 'pending', 'generating', 'completed', 'failed'
  - Handles null/undefined status gracefully

- **Types:** `status` (String) - One of the valid status values from GeneratedPlanDetailDTO

- **Props:** `status` (String) - Plan status from GeneratedPlanDetailDTO.status

### PlanContentSection

- **Component description:** Wrapper component that displays the full plan content only when status is 'completed'. Conditionally renders based on plan status and content availability.

- **Main elements:**
  - Conditional wrapper div
  - PlanSummaryCard component
  - DailyItinerarySection component
  - PlanRatingSection component

- **Handled interactions:** None (wrapper only)

- **Handled validation:**
  - Verifies status is 'completed' before rendering
  - Validates content is present and not null
  - Handles missing content gracefully with fallback message

- **Types:** `content` (Schemas::GeneratedPlanContent) - Full plan content from GeneratedPlanDetailDTO.content

- **Props:** `content` (Schemas::GeneratedPlanContent) - Plan content from GeneratedPlanDetailDTO, `generated_plan` (GeneratedPlanDetailDTO) - Full plan DTO

### PlanSummaryCard

- **Component description:** Displays the trip summary information including total cost, cost per person, duration, and number of people. Uses Material Design Card styling with clear visual hierarchy.

- **Main elements:**
  - Card container with Material Design styling
  - Cost summary section with currency formatting
  - Duration and group size information
  - Icon-enhanced display elements

- **Handled interactions:** None (display only)

- **Handled validation:**
  - Validates summary data exists
  - Handles null/undefined values with fallback display
  - Validates numeric values are valid numbers

- **Types:** `summary` (Schemas::TripSummarySchema) - Summary data from GeneratedPlanContent.summary

- **Props:** `summary` (Schemas::TripSummarySchema) - Summary object from plan content

### DailyItinerarySection

- **Component description:** Container component that displays the full daily itinerary, iterating over each day and rendering DailyItineraryDay components. Organizes the itinerary chronologically.

- **Main elements:**
  - Section wrapper div
  - Iterated DailyItineraryDay components
  - Empty state message if no days present

- **Handled interactions:** None (container only)

- **Handled validation:**
  - Validates daily_itinerary array exists and is not empty
  - Handles empty array with empty state message

- **Types:** `daily_itinerary` (Array[Schemas::DailyItinerarySchema]) - Array of daily itinerary objects from GeneratedPlanContent.daily_itinerary

- **Props:** `daily_itinerary` (Array[Schemas::DailyItinerarySchema]) - Array from plan content

### DailyItineraryDay

- **Component description:** Displays a single day's itinerary including day number, date, activities list, and restaurants list. Uses Material Design Card styling with clear day separation.

- **Main elements:**
  - Day header (day number and date)
  - ActivitiesList component
  - RestaurantsList component
  - Card container with Material Design styling

- **Handled interactions:** None (display only)

- **Handled validation:**
  - Validates day number is a positive integer
  - Validates date is in ISO 8601 format (YYYY-MM-DD)
  - Validates activities and restaurants arrays exist

- **Types:** `day` (Schemas::DailyItinerarySchema) - Single day itinerary object

- **Props:** `day` (Schemas::DailyItinerarySchema) - Single day object from daily_itinerary array

### ActivitiesList

- **Component description:** Container component that displays a list of activities for a specific day. Iterates over activities and renders ActivityItem components.

- **Main elements:**
  - List container div
  - Iterated ActivityItem components
  - Empty state message if no activities

- **Handled interactions:** None (container only)

- **Handled validation:**
  - Validates activities array exists
  - Handles empty array gracefully

- **Types:** `activities` (Array[Schemas::ActivitySchema]) - Array of activity objects from DailyItinerarySchema.activities

- **Props:** `activities` (Array[Schemas::ActivitySchema]) - Activities array from day object

### ActivityItem

- **Component description:** Displays a single activity with all its details: time, name, duration, costs (total and per-person), rating, and description. Uses Material Design Card styling with clear information hierarchy.

- **Main elements:**
  - Activity card container
  - Time display with icon
  - Activity name (heading)
  - Duration display
  - Cost information (total and per-person) with currency formatting
  - Star rating display (0-5 scale, visual stars)
  - Description text

- **Handled interactions:** None (display only)

- **Handled validation:**
  - Validates all required fields exist (time, name, duration_minutes, costs, rating, description)
  - Validates duration_minutes is a positive integer
  - Validates costs are non-negative numbers
  - Validates rating is between 0.0 and 5.0
  - Handles null/undefined values with fallback display

- **Types:** `activity` (Schemas::ActivitySchema) - Single activity object

- **Props:** `activity` (Schemas::ActivitySchema) - Single activity object from activities array

### RestaurantsList

- **Component description:** Container component that displays a list of restaurant recommendations for a specific day. Iterates over restaurants and renders RestaurantItem components.

- **Main elements:**
  - List container div
  - Iterated RestaurantItem components
  - Empty state message if no restaurants

- **Handled interactions:** None (container only)

- **Handled validation:**
  - Validates restaurants array exists
  - Handles empty array gracefully

- **Types:** `restaurants` (Array[Schemas::RestaurantSchema]) - Array of restaurant objects from DailyItinerarySchema.restaurants

- **Props:** `restaurants` (Array[Schemas::RestaurantSchema]) - Restaurants array from day object

### RestaurantItem

- **Component description:** Displays a single restaurant recommendation with meal type, name, cuisine, cost per person, and rating. Uses Material Design Card styling with meal type badge.

- **Main elements:**
  - Restaurant card container
  - Meal type badge (breakfast/lunch/dinner) with color coding
  - Restaurant name (heading)
  - Cuisine type display
  - Cost per person display with currency formatting
  - Star rating display (0-5 scale, visual stars)

- **Handled interactions:** None (display only)

- **Handled validation:**
  - Validates all required fields exist (meal, name, cuisine, estimated_cost_per_person_usd, rating)
  - Validates meal is one of: 'breakfast', 'lunch', 'dinner'
  - Validates cost is a non-negative number
  - Validates rating is between 0.0 and 5.0
  - Handles null/undefined values with fallback display

- **Types:** `restaurant` (Schemas::RestaurantSchema) - Single restaurant object

- **Props:** `restaurant` (Schemas::RestaurantSchema) - Single restaurant object from restaurants array

### PlanRatingSection

- **Component description:** Displays the rating interface for the completed plan. Shows current rating if one exists, and provides a form to submit or update the rating (1-10 scale).

- **Main elements:**
  - Section header
  - Current rating display (if rated)
  - RatingForm component

- **Handled interactions:**
  - Displays current rating value
  - Provides form for rating submission

- **Handled validation:**
  - Validates plan status is 'completed' before showing rating interface
  - Validates current rating is between 1 and 10 if present

- **Types:** `generated_plan` (GeneratedPlanDetailDTO) - Full plan DTO with rating field

- **Props:** `generated_plan` (GeneratedPlanDetailDTO) - Full plan DTO

### RatingForm

- **Component description:** Form component for submitting or updating a plan rating. Uses Turbo for seamless form submission without full page reload. Displays rating input with visual feedback.

- **Main elements:**
  - Form element with Turbo attributes
  - Rating input (number input, range slider, or star selector - 1-10 scale)
  - Submit button
  - CSRF token (automatically included by `form_with`)

- **Handled interactions:**
  - Form submission via POST/PATCH to update rating
  - Turbo Stream response for dynamic updates
  - Form validation before submission

- **Handled validation:**
  - Validates rating is an integer between 1 and 10
  - Validates plan status is 'completed' (handled server-side)
  - Displays inline error messages for validation failures
  - Prevents submission if rating is invalid

- **Types:** `generated_plan` (GeneratedPlanDetailDTO) - Full plan DTO, `trip` (Trip model) - Parent trip

- **Props:** `generated_plan` (GeneratedPlanDetailDTO) - Full plan DTO, `trip` (Trip model) - Parent trip model

### NavigationActions

- **Component description:** Provides navigation actions including a link back to the trip detail page. Optional delete action for future implementation.

- **Main elements:**
  - Back to Trip link/button
  - Optional delete button (future feature)

- **Handled interactions:**
  - Navigation to trip detail page
  - Optional delete confirmation dialog (future)

- **Handled validation:** None

- **Types:** `trip` (Trip model) - Parent trip

- **Props:** `trip` (Trip model) - Parent trip model

## 5. Types

### DTOs (Data Transfer Objects)

#### GeneratedPlanDetailDTO

The main DTO for the generated plan detail view, containing all plan information including full structured content.

**Fields:**
- `id` (Integer) - Unique identifier for the generated plan
- `trip_id` (Integer) - ID of the associated trip
- `status` (String) - Plan status: 'pending', 'generating', 'completed', or 'failed'
- `rating` (Integer | nil) - User rating (1-10) or nil if not rated
- `created_at` (String) - ISO 8601 formatted creation timestamp
- `updated_at` (String) - ISO 8601 formatted update timestamp
- `content` (Schemas::GeneratedPlanContent | nil) - Full structured plan content (only when status is 'completed')

**Factory Method:** `DTOs::GeneratedPlanDetailDTO.from_model(plan: GeneratedPlan)`

**Location:** `app/types/dtos/generated_plan_detail_dto.rb`

### Schema Types

#### Schemas::GeneratedPlanContent

Top-level structure for generated plan content, containing summary and daily itinerary.

**Fields:**
- `summary` (Schemas::TripSummarySchema) - Trip summary information
- `daily_itinerary` (Array[Schemas::DailyItinerarySchema]) - Array of daily itinerary objects

**Factory Method:** `Schemas::GeneratedPlanContent.from_json(json_string: String)`

**Location:** `app/types/schemas/generated_plan_content.rb`

#### Schemas::TripSummarySchema

Summary information for the entire trip.

**Fields:**
- `total_cost_usd` (Float) - Total estimated cost for all people in USD
- `cost_per_person_usd` (Float) - Estimated cost per person in USD
- `duration_days` (Integer) - Number of days in the trip
- `number_of_people` (Integer) - Number of travelers

**Location:** `app/types/schemas/generated_plan_content.rb`

#### Schemas::DailyItinerarySchema

Daily itinerary with activities and restaurant recommendations for a single day.

**Fields:**
- `day` (Integer) - Day number (1, 2, 3, etc.)
- `date` (String) - ISO 8601 date format (YYYY-MM-DD)
- `activities` (Array[Schemas::ActivitySchema]) - Array of activities for the day
- `restaurants` (Array[Schemas::RestaurantSchema]) - Array of restaurant recommendations for the day

**Location:** `app/types/schemas/generated_plan_content.rb`

#### Schemas::ActivitySchema

Activity information within a day's itinerary.

**Fields:**
- `time` (String) - Time string (e.g., "10:00 AM")
- `name` (String) - Activity name
- `duration_minutes` (Integer) - Duration in minutes
- `estimated_cost_usd` (Float) - Total estimated cost in USD
- `estimated_cost_per_person_usd` (Float) - Estimated cost per person in USD
- `rating` (Float) - Rating (0.0-5.0 scale)
- `description` (String) - Activity description

**Location:** `app/types/schemas/generated_plan_content.rb`

#### Schemas::RestaurantSchema

Restaurant recommendation for a meal.

**Fields:**
- `meal` (String) - Meal type: "breakfast", "lunch", or "dinner"
- `name` (String) - Restaurant name
- `cuisine` (String) - Cuisine type
- `estimated_cost_per_person_usd` (Float) - Estimated cost per person in USD
- `rating` (Float) - Rating (0.0-5.0 scale)

**Location:** `app/types/schemas/generated_plan_content.rb`

### Command Models

#### Commands::GeneratedPlanUpdateCommand

Command model for updating a generated plan rating.

**Fields:**
- `rating` (Integer | nil) - Rating value (1-10) or nil

**Factory Method:** `Commands::GeneratedPlanUpdateCommand.from_params(params: Hash)`

**Location:** `app/types/commands/generated_plan_update_command.rb`

### Model Types

#### GeneratedPlan

ActiveRecord model representing a generated plan in the database.

**Key Attributes:**
- `id` (Integer)
- `trip_id` (Integer)
- `status` (String) - Validated against Enums::GeneratedPlanStatus
- `rating` (Integer | nil) - Validated to be 1-10 if present
- `content` (String) - JSON string of plan content
- `created_at` (DateTime)
- `updated_at` (DateTime)

**Location:** `app/models/generated_plan.rb`

#### Trip

ActiveRecord model representing a trip (used for navigation and context).

**Location:** `app/models/trip.rb`

## 6. State Management

The view is stateless and relies on server-rendered HTML with Hotwire (Turbo) for dynamic updates. No client-side state management libraries are required.

### View State

**Initial State:**
- Plan data loaded from server via GET request
- Status determines which components are displayed
- Rating form state initialized from current rating value

**Dynamic Updates:**
- Turbo Streams handle real-time status updates when plan generation completes
- Rating form submissions update the view without full page reload
- Status changes (pending → generating → completed/failed) trigger component visibility changes

### Custom Hooks

No custom Stimulus hooks are required for basic functionality. Optional enhancements could include:
- Auto-refresh polling for 'generating' status (using Stimulus controller)
- Smooth scroll animations (using Stimulus controller)
- Rating input interactive feedback (using Stimulus controller)

### Turbo Streams Integration

The view supports Turbo Stream updates for:
- Status changes (when plan generation completes)
- Rating updates (after form submission)
- Error messages (validation failures)

## 7. API Integration

### GET /trips/:trip_id/generated_plans/:id

**Request:**
- **Method:** `GET`
- **Path:** `/trips/:trip_id/generated_plans/:id`
- **Headers:**
  - `Accept: text/html` (for HTML view)
  - Session cookie (authentication via Devise)
- **Parameters:**
  - `trip_id` (route parameter) - Integer trip ID
  - `id` (route parameter) - Integer generated plan ID

**Success Response (200 OK):**

**HTML Format:**
- Renders `app/views/trips/generated_plans/show.html.erb` with plan data loaded in `@generated_plan`
- Plan loaded with authorization: `@generated_plan = @trip.generated_plans.find(params[:id])`
- DTO transformation: `DTOs::GeneratedPlanDetailDTO.from_model(@generated_plan)`

**JSON Format (if requested):**
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
              "description": "Visit the iconic Eiffel Tower..."
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

**Alternative Response (202 Accepted):**
When plan status is 'generating' or 'pending', the API may return 202 Accepted with a message:
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

**Error Responses:**
- `401 Unauthorized`: User not authenticated (handled by Devise, redirects to login)
- `404 Not Found`: Generated plan not found or doesn't belong to user
  ```json
  {
    "error": "Generated plan not found"
  }
  ```

### PATCH /trips/:trip_id/generated_plans/:id (Rating Update)

**Request:**
- **Method:** `PATCH`
- **Path:** `/trips/:trip_id/generated_plans/:id`
- **Headers:**
  - `Accept: text/html` (for HTML response)
  - Session cookie (authentication)
  - CSRF token (via `form_with`)
  - `Content-Type: application/x-www-form-urlencoded` (form submission)
- **Request Body:**
  ```json
  {
    "generated_plan": {
      "rating": 8
    }
  }
  ```

**Success Response (200 OK):**

**HTML Format:**
- Turbo Stream update to refresh rating display
- Flash message: `flash[:notice] = 'Rating saved successfully'`

**JSON Format (if requested):**
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

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `404 Not Found`: Generated plan not found
- `422 Unprocessable Content`: Invalid rating
  ```json
  {
    "errors": {
      "rating": ["must be between 1 and 10"]
    }
  }
  ```

## 8. User Interactions

### View Plan (Navigation)

**Interaction:** User clicks "View Plan" link on the Generated Plans tab on Trip Detail page.

**Expected Outcome:**
- User navigates to `/trips/:trip_id/generated_plans/:id`
- Full plan view displays with all details
- Status banner shows current plan status
- If completed, full content is displayed
- If generating/pending, loading state is shown
- If failed, error message is displayed

### Submit Rating

**Interaction:** User selects a rating (1-10) and submits the rating form.

**Expected Outcome:**
- Form submits via Turbo (no full page reload)
- Rating is saved to the database
- UI updates to show the new rating value
- Success message appears (toast/snackbar)
- Rating input reflects the saved value

**Error Handling:**
- If validation fails (rating out of range), inline error message appears
- Form remains with user input preserved
- User can correct and resubmit

### Navigate Back to Trip

**Interaction:** User clicks "Back to Trip" link.

**Expected Outcome:**
- User navigates back to `/trips/:id`
- Generated Plans tab should be active (optional enhancement)

### Auto-Refresh (Optional Enhancement)

**Interaction:** User is viewing a plan with 'generating' status.

**Expected Outcome (if implemented):**
- View automatically polls the endpoint every 5 seconds
- Status updates when generation completes
- Polling stops when status changes to 'completed' or 'failed'

## 9. Conditions and Validation

### View-Level Conditions

**Plan Status Check:**
- **Condition:** Plan status must be validated before rendering content
- **Validation:** Status must be one of: 'pending', 'generating', 'completed', 'failed'
- **UI Impact:**
  - If 'pending' or 'generating': Show loading state banner, hide content section
  - If 'completed': Show content section with full plan details
  - If 'failed': Show error state banner, hide content section

**Content Availability Check:**
- **Condition:** Content must exist and be valid JSON when status is 'completed'
- **Validation:** Content field must be present and parseable as GeneratedPlanContent schema
- **UI Impact:**
  - If content missing: Show error message, hide content section
  - If content invalid: Show error message, attempt graceful degradation

### Component-Level Validation

**PlanSummaryCard:**
- **Condition:** Summary data must be present
- **Validation:** All summary fields (total_cost_usd, cost_per_person_usd, duration_days, number_of_people) must be valid numbers
- **UI Impact:** Missing or invalid values show fallback text (e.g., "N/A")

**ActivityItem:**
- **Condition:** All required activity fields must be present
- **Validation:**
  - `duration_minutes` must be a positive integer
  - `estimated_cost_usd` and `estimated_cost_per_person_usd` must be non-negative numbers
  - `rating` must be between 0.0 and 5.0
- **UI Impact:** Invalid values show fallback or error indicator

**RestaurantItem:**
- **Condition:** All required restaurant fields must be present
- **Validation:**
  - `meal` must be one of: 'breakfast', 'lunch', 'dinner'
  - `estimated_cost_per_person_usd` must be a non-negative number
  - `rating` must be between 0.0 and 5.0
- **UI Impact:** Invalid values show fallback or error indicator

**RatingForm:**
- **Condition:** Rating can only be submitted for completed plans
- **Validation:**
  - Rating must be an integer between 1 and 10
  - Plan status must be 'completed' (server-side validation)
- **UI Impact:**
  - If status is not 'completed': Form is disabled or hidden
  - If rating invalid: Inline error message appears, form remains editable

### API Response Validation

**Status-Based Response Handling:**
- **Condition:** API may return 202 Accepted for generating plans
- **Validation:** Check response status code
- **UI Impact:**
  - 200 OK: Display plan content
  - 202 Accepted: Show generating state with appropriate message

**Error Response Handling:**
- **Condition:** API may return error responses
- **Validation:** Check response status codes (404, 422, 500)
- **UI Impact:**
  - 404: Show "Plan not found" error message
  - 422: Show validation errors (for rating form)
  - 500: Show generic error message

## 10. Error Handling

### Loading Errors

**Plan Not Found (404):**
- **Scenario:** User tries to view a plan that doesn't exist or doesn't belong to them
- **Handling:**
  - Controller returns 404
  - View shows error message: "Travel plan not found. It may have been deleted or you don't have permission to view it."
  - Display "Back to Trip" link

**Invalid Plan ID:**
- **Scenario:** Invalid or non-numeric plan ID in URL
- **Handling:**
  - Rails routing handles invalid format
  - Returns 404 Not Found

### Content Errors

**Missing Content:**
- **Scenario:** Plan status is 'completed' but content field is null or empty
- **Handling:**
  - Check content presence before rendering PlanContentSection
  - Display message: "Plan content is unavailable. Please regenerate the plan."
  - Show status banner with 'failed' or error indicator

**Invalid JSON Content:**
- **Scenario:** Content field contains invalid JSON that cannot be parsed
- **Handling:**
  - Catch JSON parsing errors in DTO transformation
  - Display error message: "Plan content is corrupted. Please regenerate the plan."
  - Log error for debugging

**Missing Required Fields:**
- **Scenario:** Content JSON is missing required fields (e.g., summary, activities)
- **Handling:**
  - Use safe navigation operators (`&.`) when accessing nested properties
  - Display fallback values or "N/A" for missing data
  - Log warnings for missing expected data

### Form Submission Errors

**Invalid Rating:**
- **Scenario:** User submits rating outside 1-10 range or non-integer value
- **Handling:**
  - Server validates and returns 422 Unprocessable Content
  - Form re-renders with inline error messages
  - Highlight invalid input field
  - Preserve user input (except invalid value)

**Rating for Non-Completed Plan:**
- **Scenario:** User tries to rate a plan that is not completed
- **Handling:**
  - Server validates status is 'completed' before allowing rating
  - Returns 422 with error: "Rating can only be set for completed plans"
  - Display error message in UI
  - Disable rating form if status is not 'completed'

**Network Errors:**
- **Scenario:** Network failure during form submission
- **Handling:**
  - Turbo handles network errors and displays error state
  - Show toast message: "Failed to save rating. Please try again."
  - Form remains editable with user input preserved

### Status Transition Errors

**Unexpected Status:**
- **Scenario:** Plan has an unexpected status value
- **Handling:**
  - Validate status against known values
  - Default to 'pending' styling for unknown statuses
  - Log warning for unexpected status values

**Generation Failure:**
- **Scenario:** Plan status is 'failed'
- **Handling:**
  - Display error banner with red status chip
  - Show message: "Plan generation failed. Please try generating a new plan."
  - Hide content section
  - Provide link to regenerate plan (if applicable)

### Graceful Degradation

**Partial Data:**
- **Scenario:** Some fields in content are missing or null
- **Handling:**
  - Use safe navigation to prevent errors
  - Display "N/A" or placeholder text for missing values
  - Continue rendering other valid data

**Large Content:**
- **Scenario:** Plan contains many days/activities causing performance issues
- **Handling:**
  - Use lazy loading or pagination for very long itineraries (future enhancement)
  - Optimize rendering with efficient loops
  - Monitor performance and optimize as needed

## 11. Implementation Steps

1. **Add Route for Show Action:**
   - Update `config/routes.rb` to include `:show` in the `generated_plans` nested resources
   - Route should be: `resources :generated_plans, only: [:create, :show], module: :trips`

2. **Implement Controller Show Action:**
   - Add `show` action to `app/controllers/trips/generated_plans_controller.rb`
   - Load trip: `@trip = current_user.trips.find(params[:trip_id])`
   - Load generated plan: `@generated_plan_model = @trip.generated_plans.find(params[:id])`
   - Transform to DTO: `@generated_plan = DTOs::GeneratedPlanDetailDTO.from_model(@generated_plan_model)`
   - Implement `respond_to` block for HTML and JSON formats
   - Handle `ActiveRecord::RecordNotFound` (automatically via ApplicationController rescue_from)

3. **Create Main View Template:**
   - Create `app/views/trips/generated_plans/show.html.erb`
   - Add Material Tailwind controller: `data-controller="material-tailwind"`
   - Render shared page header
   - Render plan status banner
   - Conditionally render plan content section (only if status is 'completed' and content present)
   - Render navigation actions

4. **Create PlanStatusBanner Partial:**
   - Create `app/views/trips/generated_plans/_plan_status_banner.html.erb`
   - Implement status chip with color coding (gray/blue/green/red)
   - Add animated spinner for 'generating' status
   - Display appropriate status message based on status value

5. **Create PlanContentSection Partial:**
   - Create `app/views/trips/generated_plans/_plan_content_section.html.erb`
   - Add conditional wrapper (only render if status is 'completed' and content present)
   - Render plan summary card
   - Render daily itinerary section
   - Render plan rating section

6. **Create PlanSummaryCard Partial:**
   - Create `app/views/trips/generated_plans/_plan_summary_card.html.erb`
   - Display total cost with currency formatting ($X,XXX.XX)
   - Display cost per person with currency formatting
   - Display duration in days
   - Display number of people
   - Use Material Design card styling

7. **Create DailyItinerarySection Partial:**
   - Create `app/views/trips/generated_plans/_daily_itinerary_section.html.erb`
   - Iterate over `daily_itinerary` array
   - Render DailyItineraryDay partial for each day
   - Add empty state message if array is empty

8. **Create DailyItineraryDay Partial:**
   - Create `app/views/trips/generated_plans/_daily_itinerary_day.html.erb`
   - Display day header with day number and formatted date
   - Render activities list
   - Render restaurants list
   - Use Material Design card styling with proper spacing

9. **Create ActivitiesList Partial:**
   - Create `app/views/trips/generated_plans/_activities_list.html.erb`
   - Iterate over activities array
   - Render ActivityItem partial for each activity
   - Add empty state if no activities

10. **Create ActivityItem Partial:**
    - Create `app/views/trips/generated_plans/_activity_item.html.erb`
    - Display time with icon
    - Display activity name as heading
    - Display duration in hours/minutes format
    - Display costs (total and per-person) with currency formatting
    - Display star rating (0-5 scale, visual representation)
    - Display description text
    - Use Material Design card styling

11. **Create RestaurantsList Partial:**
    - Create `app/views/trips/generated_plans/_restaurants_list.html.erb`
    - Iterate over restaurants array
    - Render RestaurantItem partial for each restaurant
    - Add empty state if no restaurants

12. **Create RestaurantItem Partial:**
    - Create `app/views/trips/generated_plans/_restaurant_item.html.erb`
    - Display meal type badge with color coding (breakfast/lunch/dinner)
    - Display restaurant name as heading
    - Display cuisine type
    - Display cost per person with currency formatting
    - Display star rating (0-5 scale, visual representation)
    - Use Material Design card styling

13. **Create PlanRatingSection Partial:**
    - Create `app/views/trips/generated_plans/_plan_rating_section.html.erb`
    - Conditionally display current rating if present (1-10 scale with visual stars)
    - Render rating form (only if status is 'completed')

14. **Create RatingForm Partial:**
    - Create `app/views/trips/generated_plans/_rating_form.html.erb`
    - Use `form_with` helper with Turbo support
    - Implement rating input (number input or range slider, 1-10)
    - Add submit button
    - Include inline error message display
    - Form action: `trip_generated_plan_path(@trip, @generated_plan)`
    - Form method: PATCH
    - Add Turbo Stream target for dynamic updates

15. **Create NavigationActions Partial:**
    - Create `app/views/trips/generated_plans/_navigation_actions.html.erb`
    - Add "Back to Trip" link to `trip_path(@trip)`
    - Style as Material Design button or link

16. **Implement Controller Update Action (for Rating):**
    - Add `update` action to `app/controllers/trips/generated_plans_controller.rb`
    - Load trip and plan (same as show action)
    - Parse command: `command = Commands::GeneratedPlanUpdateCommand.from_params(params)`
    - Update plan: `@generated_plan_model.update!(command.to_model_attributes)`
    - Transform to DTO for response
    - Implement `respond_to` block for HTML (Turbo Stream) and JSON formats
    - Handle validation errors (422 response)
    - Return success message

17. **Add Update Route:**
    - Update `config/routes.rb` to include `:update` in the `generated_plans` nested resources
    - Route should be: `resources :generated_plans, only: [:create, :show, :update], module: :trips`

18. **Create Turbo Stream Template for Rating Update:**
    - Create `app/views/trips/generated_plans/update.turbo_stream.erb`
    - Update rating section with new rating value
    - Display success flash message
    - Optionally refresh the entire rating section

19. **Update Generated Plan Item Partial:**
    - Update `app/views/trips/_generated_plan_item.html.erb`
    - Change "View Plan" link href from `'#'` to `trip_generated_plan_path(trip, plan)`

20. **Add Error Handling:**
    - Implement error partials for 404 and other error states
    - Add error messages for missing content
    - Add validation error displays in rating form

21. **Add Helper Methods (Optional):**
    - Create view helpers for currency formatting: `format_currency(amount)`
    - Create view helpers for duration formatting: `format_duration(minutes)`
    - Create view helpers for rating display: `display_rating(rating, max_rating)`

22. **Add Accessibility Features:**
    - Add proper ARIA labels to interactive elements
    - Ensure keyboard navigation works for all components
    - Add semantic HTML elements (`<section>`, `<article>`, etc.)
    - Ensure color contrast meets WCAG standards

23. **Test Implementation:**
    - Test with completed plans (full content display)
    - Test with generating plans (loading state)
    - Test with failed plans (error state)
    - Test rating submission and updates
    - Test error scenarios (404, invalid content, etc.)
    - Test responsive design on mobile devices
    - Test accessibility with screen readers

24. **Optimize Performance:**
    - Ensure efficient rendering of large itineraries
    - Add lazy loading if needed for very long plans
    - Optimize database queries (eager loading if needed)
    - Monitor rendering performance

