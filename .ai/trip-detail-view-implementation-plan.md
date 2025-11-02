# View Implementation Plan: Trip Detail

## 1. Overview

The Trip Detail view provides a comprehensive interface for viewing and managing a single trip, including its associated notes and AI-generated travel plans. The view implements a tabbed interface to organize related information, allowing users to switch between "Notes" and "Generated Plans" sections seamlessly. The view uses Material Design principles via Material Tailwind CSS and leverages Hotwire (Turbo and Stimulus) for dynamic, real-time updates. The implementation follows Rails conventions, uses reusable shared components, and ensures proper accessibility and security measures.

**Key Features:**
- Display trip header with key information (name, destination, dates, number of people)
- Tabbed interface for organizing Notes and Generated Plans
- Add and manage notes within the Notes tab
- View generated plans with status indicators in the Generated Plans tab
- Initiate new plan generation with real-time status updates via Turbo Streams
- Delete trip with confirmation dialog (requires US-010)
- Edit trip navigation link

## 2. View Routing

- **Path:** `/trips/:id`
- **HTTP Method:** `GET`
- **Controller Action:** `TripsController#show`
- **Route Helper:** `trip_path(@trip)`
- **Authentication:** Required (protected by `before_action :authenticate_user!`)
- **Authorization:** User can only view their own trips (enforced by `current_user.trips.find(params[:id])`)

## 3. Component Structure

The Trip Detail view is composed of reusable and view-specific components organized hierarchically:

```
app/views/trips/show.html.erb (Main Container)
├── render 'shared/page_header'
│   └── Title and optional description
├── TripHeader Partial (_trip_header.html.erb)
│   ├── Trip name (h2)
│   ├── Destination display
│   ├── Date range display
│   ├── Number of people display
│   ├── Edit button/link
│   └── Delete button with confirmation
├── TabNavigation Component (_tab_navigation.html.erb)
│   ├── Tab List (ul with ARIA tablist role)
│   │   ├── Notes Tab Button (active/inactive states)
│   │   └── Generated Plans Tab Button (active/inactive states)
│   └── Tab Panels Container
│       ├── Notes Tab Panel (_notes_tab.html.erb)
│       │   ├── Notes List (_notes_list.html.erb)
│       │   │   └── Note Item (_note_item.html.erb) [repeated]
│       │   └── Add Note Form (_add_note_form.html.erb)
│       └── Generated Plans Tab Panel (_generated_plans_tab.html.erb)
│           ├── Generate Plan Button
│           └── Generated Plans List (_generated_plans_list.html.erb)
│               └── Generated Plan Item (_generated_plan_item.html.erb) [repeated]
│                   ├── Status Chip (Material Design)
│                   ├── Created date
│                   ├── Rating display (if rated)
│                   └── View/Expand link
```

**Partials Structure:**
- `app/views/trips/show.html.erb`: Main view file
- `app/views/trips/_trip_header.html.erb`: Trip information header
- `app/views/trips/_tab_navigation.html.erb`: Tab navigation component
- `app/views/trips/_notes_tab.html.erb`: Notes tab content
- `app/views/trips/_notes_list.html.erb`: List of notes
- `app/views/trips/_note_item.html.erb`: Individual note display
- `app/views/trips/_add_note_form.html.erb`: Form to add new note
- `app/views/trips/_generated_plans_tab.html.erb`: Generated Plans tab content
- `app/views/trips/_generated_plans_list.html.erb`: List of generated plans
- `app/views/trips/_generated_plan_item.html.erb`: Individual generated plan display

## 4. Component Details

### TripHeader Partial (_trip_header.html.erb)

- **Component description:** Displays the trip's core information in a visually prominent header section, along with action buttons for editing and deleting the trip. Serves as the primary information display for the trip.

- **Main elements:**
  - Container `<div>` with Material Design card styling
  - Trip name as `<h2>` heading
  - Destination displayed as text with icon (optional)
  - Date range display (start_date to end_date) formatted for readability
  - Number of people display with appropriate label
  - Edit button/link (`link_to` to `edit_trip_path(@trip)`) styled as secondary button
  - Delete button (`button_to` with `DELETE` method to `trip_path(@trip)`) styled as danger/outline button with `data-turbo-confirm` attribute for confirmation dialog

- **Handled interactions:**
  - Click on Edit button: Navigate to edit form (`GET /trips/:id/edit`)
  - Click on Delete button: Show browser confirmation dialog (via `data-turbo-confirm`), then submit DELETE request to `/trips/:id` if confirmed

- **Handled validation:** None (display-only component)

- **Types:**
  - `TripDTO` or `Trip` model instance (via `@trip` from controller)

- **Props:**
  - `trip` (required): Trip model instance or DTO containing:
    - `id: Integer`
    - `name: String`
    - `destination: String`
    - `start_date: String` (ISO 8601 format: YYYY-MM-DD)
    - `end_date: String` (ISO 8601 format: YYYY-MM-DD)
    - `number_of_people: Integer`

### TabNavigation Component (_tab_navigation.html.erb)

- **Component description:** Implements an accessible tab interface using ARIA roles to switch between Notes and Generated Plans tabs. Uses Stimulus controller for tab state management and smooth transitions between tab panels.

- **Main elements:**
  - Container `<div>` with tab navigation styling
  - `<ul>` with `role="tablist"` and `aria-label="Trip sections"`
  - Two `<li>` elements, each containing:
    - `<button>` with `role="tab"`, `aria-selected` attribute, `aria-controls` pointing to corresponding tabpanel, and Stimulus actions
  - Tab panels container with two `<div>` elements:
    - Notes Tab Panel (`role="tabpanel"`, `id="notes-tabpanel"`, `aria-labelledby="notes-tab"`)
    - Generated Plans Tab Panel (`role="tabpanel"`, `id="generated-plans-tabpanel"`, `aria-labelledby="generated-plans-tab"`)

- **Handled interactions:**
  - Click on tab button: Switch active tab, update `aria-selected` attributes, show/hide corresponding tab panels, update Stimulus controller state
  - Keyboard navigation (Arrow keys to switch tabs, Enter/Space to activate)

- **Handled validation:** None (UI navigation component)

- **Types:** None (pure UI component)

- **Props:**
  - `active_tab` (optional, default: 'notes'): String indicating which tab should be active initially ('notes' or 'generated_plans')
  - `trip` (required): Trip model instance for passing to tab panel partials

### NotesTab Partial (_notes_tab.html.erb)

- **Component description:** Displays the Notes tab content, including a list of all notes associated with the trip and a form to add new notes. Notes are displayed in chronological order (newest first or oldest first, as per design requirements).

- **Main elements:**
  - Container `<div>` with tab panel styling
  - Notes list section (`render 'notes_list', notes: @trip.notes`)
  - Add note form section (`render 'add_note_form', trip: @trip`)

- **Handled interactions:**
  - Delegated to child components (notes list and add note form)

- **Handled validation:** None (delegated to add note form)

- **Types:**
  - `TripDTO` with `notes: Array[NoteDTO]` or `Trip` model with `has_many :notes`

- **Props:**
  - `trip` (required): Trip model instance with loaded notes association

### NotesList Partial (_notes_list.html.erb)

- **Component description:** Renders a list of notes for the trip, with each note displayed as a card or list item. Supports empty state display when no notes exist.

- **Main elements:**
  - Conditional rendering:
    - If `notes.any?`: `<ul>` or `<div>` container iterating over notes, rendering `_note_item` partial for each
    - If `notes.empty?`: Empty state message (e.g., "No notes yet. Add your first note below.")

- **Handled interactions:** None directly (delegated to note items)

- **Handled validation:** None

- **Types:**
  - `notes: Array[NoteDTO]` or `ActiveRecord::Association[Note]`

- **Props:**
  - `notes` (required): Array of NoteDTO objects or ActiveRecord association of Note models

### NoteItem Partial (_note_item.html.erb)

- **Component description:** Displays a single note with its content and timestamps. Provides options to edit or delete the note (if those actions are implemented).

- **Main elements:**
  - Container `<div>` or `<li>` with note card styling
  - Note content as `<p>` (with proper text wrapping and escaping)
  - Created/updated timestamp display (formatted for readability)
  - Optional action buttons (Edit, Delete) if functionality is implemented

- **Handled interactions:**
  - If edit functionality exists: Navigate to edit note form or inline edit
  - If delete functionality exists: Show confirmation and delete note via DELETE request

- **Handled validation:** None (display component)

- **Types:**
  - `NoteDTO` with fields:
    - `id: Integer`
    - `trip_id: Integer`
    - `content: String`
    - `created_at: String` (ISO 8601 datetime)
    - `updated_at: String` (ISO 8601 datetime)

- **Props:**
  - `note` (required): NoteDTO object or Note model instance

### AddNoteForm Partial (_add_note_form.html.erb)

- **Component description:** Provides a form to add a new note to the trip. Uses Turbo for form submission to enable seamless updates without full page reload.

- **Main elements:**
  - `<%= form_with model: [@trip, Note.new], local: false, data: { turbo_frame: 'notes_list' } do |form| %>`
  - Text area for note content (`form.text_area :content`)
  - Label for text area (`form.label :content`)
  - Submit button
  - Error message container (displayed via Turbo Streams on validation errors)

- **Handled interactions:**
  - Form submission: POST request to `/trips/:trip_id/notes` via Turbo
  - On success: Turbo Stream updates notes list, clears form
  - On validation error: Turbo Stream displays inline error messages

- **Handled validation:**
  - Content must be present (server-side validation)
  - Content cannot be blank (server-side validation)
  - Maximum length: 10,000 characters (server-side validation)
  - Client-side: Optional validation for immediate feedback (can be added with Stimulus)

- **Types:**
  - Form uses `Note` model (new, unsaved instance)
  - Response: `NoteDTO` on success, `ErrorResponseDTO` on validation failure

- **Props:**
  - `trip` (required): Trip model instance (used for form route)

### GeneratedPlansTab Partial (_generated_plans_tab.html.erb)

- **Component description:** Displays the Generated Plans tab content, including a button to initiate plan generation and a list of all generated plans for the trip with their status indicators.

- **Main elements:**
  - Container `<div>` with tab panel styling
  - "Generate Plan" button section (prominently displayed)
  - Generated plans list section (`render 'generated_plans_list', plans: @trip.generated_plans`)

- **Handled interactions:**
  - Click on "Generate Plan" button: POST request to `/trips/:trip_id/generated_plans` to initiate generation

- **Handled validation:** None directly (delegated to generation endpoint)

- **Types:**
  - `TripDTO` with `generated_plans: Array[GeneratedPlanDTO]` or `Trip` model with `has_many :generated_plans`

- **Props:**
  - `trip` (required): Trip model instance with loaded generated_plans association

### GeneratedPlansList Partial (_generated_plans_list.html.erb)

- **Component description:** Renders a list of generated plans, sorted by creation date (newest first). Each plan displays its status, creation date, and optional rating.

- **Main elements:**
  - Conditional rendering:
    - If `plans.any?`: `<ul>` or `<div>` container iterating over plans, rendering `_generated_plan_item` partial for each
    - If `plans.empty?`: Empty state message (e.g., "No generated plans yet. Click 'Generate Plan' to create your first plan.")

- **Handled interactions:** None directly (delegated to plan items)

- **Handled validation:** None

- **Types:**
  - `plans: Array[GeneratedPlanDTO]` or `ActiveRecord::Association[GeneratedPlan]`

- **Props:**
  - `plans` (required): Array of GeneratedPlanDTO objects or ActiveRecord association of GeneratedPlan models

### GeneratedPlanItem Partial (_generated_plan_item.html.erb)

- **Component description:** Displays a single generated plan with its status indicated by a colored Material Design Chip, creation date, optional rating, and a link to view full plan details (for US-016).

- **Main elements:**
  - Container `<div>` or `<li>` with plan card styling
  - Status Chip (Material Design component) with color coding:
    - `pending`: Gray/yellow chip
    - `generating`: Blue chip with loading indicator (optional spinner)
    - `completed`: Green chip
    - `failed`: Red chip
  - Creation date display (formatted for readability)
  - Rating display (if `rating` is present, display as stars or number, e.g., "Rating: 8/10")
  - Link to view full plan (route to plan detail view, if implemented for US-016)

- **Handled interactions:**
  - Click on view link: Navigate to plan detail view (if implemented)
  - Status updates via Turbo Streams (real-time status changes from `generating` to `completed`/`failed`)

- **Handled validation:** None (display component)

- **Types:**
  - `GeneratedPlanDTO` with fields:
    - `id: Integer`
    - `trip_id: Integer`
    - `status: String` ('pending', 'generating', 'completed', 'failed')
    - `rating: Integer | nil` (1-10, nullable)
    - `created_at: String` (ISO 8601 datetime)
    - `updated_at: String` (ISO 8601 datetime)
    - `content_preview: String | nil` (optional, for list view)

- **Props:**
  - `plan` (required): GeneratedPlanDTO object or GeneratedPlan model instance

## 5. Types

### DTOs (Data Transfer Objects)

**TripDTO** (from `app/types/dtos/trip_dto.rb`):
- `id: Integer` - Trip identifier
- `name: String` - Trip name
- `destination: String` - Trip destination
- `start_date: String` - Start date in ISO 8601 format (YYYY-MM-DD)
- `end_date: String` - End date in ISO 8601 format (YYYY-MM-DD)
- `number_of_people: Integer` - Number of people in the group
- `created_at: String` - Creation timestamp in ISO 8601 format
- `updated_at: String` - Last update timestamp in ISO 8601 format
- `notes: Array[NoteDTO] | nil` - Array of associated notes (included in show view)
- `generated_plans: Array[GeneratedPlanDTO] | nil` - Array of associated generated plans (included in show view)

**NoteDTO** (from `app/types/dtos/note_dto.rb`):
- `id: Integer` - Note identifier
- `trip_id: Integer` - Associated trip identifier
- `content: String` - Note content (plain text, max 10,000 characters)
- `created_at: String` - Creation timestamp in ISO 8601 format
- `updated_at: String` - Last update timestamp in ISO 8601 format

**GeneratedPlanDTO** (from `app/types/dtos/generated_plan_dto.rb`):
- `id: Integer` - Generated plan identifier
- `trip_id: Integer` - Associated trip identifier
- `status: String` - Status value: 'pending', 'generating', 'completed', or 'failed'
- `rating: Integer | nil` - User rating (1-10, nullable)
- `created_at: String` - Creation timestamp in ISO 8601 format
- `updated_at: String` - Last update timestamp in ISO 8601 format
- `content_preview: String | nil` - Optional preview text for list view

### ViewModel Types (Component-Specific)

No custom ViewModel types are required for this view. The view uses DTOs directly from the API response and ActiveRecord model instances from the controller. Component state (active tab) is managed via Stimulus controller, not through ViewModels.

## 6. State Management

**Server-Side State:**
- Trip data, notes, and generated plans are stored in the database and loaded via `TripsController#show`
- Controller loads trip with eager-loaded associations: `@trip = current_user.trips.includes(:notes, :generated_plans).find(params[:id])`

**Client-Side State (Stimulus Controller):**

A Stimulus controller is required to manage tab navigation state:

**Controller Name:** `tabs_controller.js` (or `tab_navigation_controller.js`)

**Purpose:** Manage active tab state, handle tab switching, and ensure proper ARIA attributes are maintained for accessibility.

**State Variables:**
- `activeTab: String` - Current active tab identifier ('notes' or 'generated_plans')
- `tabButtons: NodeList` - Reference to tab button elements
- `tabPanels: NodeList` - Reference to tab panel elements

**Actions:**
- `switchTab(event)` - Switches active tab, updates ARIA attributes, shows/hides panels
- `handleKeyboardNavigation(event)` - Handles arrow key navigation between tabs

**Lifecycle:**
- `connect()` - Initialize active tab, set up ARIA attributes, attach keyboard listeners
- `disconnect()` - Clean up event listeners

**Custom Hook:** Not required. Standard Stimulus controller pattern is sufficient.

**Turbo Stream Updates:**
- Generated plan status updates are pushed from server via Turbo Streams when status changes
- Note additions are updated via Turbo Streams after successful form submission
- No polling required - server pushes updates asynchronously

## 7. API Integration

### GET /trips/:id

**Request:**
- **Method:** `GET`
- **Path:** `/trips/:id`
- **Headers:** 
  - `Accept: text/html` (for HTML view)
  - Session cookie (authentication via Devise)
- **Parameters:** `id` (route parameter) - Integer trip ID

**Response (200 OK):**

**HTML Format:**
- Renders `app/views/trips/show.html.erb` with trip data loaded in `@trip`
- Trip loaded with associations: `@trip = current_user.trips.includes(:notes, :generated_plans).find(params[:id])`

**JSON Format (if requested):**
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
        "updated_at": "2025-10-19T12:30:00Z"
      }
    ]
  }
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated (handled by Devise, redirects to login)
- `404 Not Found`: Trip not found or doesn't belong to user
  ```json
  {
    "error": "Trip not found"
  }
  ```

### DELETE /trips/:id

**Request:**
- **Method:** `DELETE`
- **Path:** `/trips/:id`
- **Headers:**
  - `Accept: text/html` (for HTML response)
  - Session cookie (authentication)
  - CSRF token (via `form_with` or `button_to`)
- **Parameters:** `id` (route parameter) - Integer trip ID

**Response (200 OK):**

**HTML Format:**
- Redirects to `trips_path` with flash message: `flash[:notice] = 'Trip deleted successfully'`

**JSON Format (if requested):**
```json
{
  "message": "Trip deleted successfully"
}
```

**Error Responses:**
- `401 Unauthorized`: User not authenticated
- `404 Not Found`: Trip not found or doesn't belong to user

### POST /trips/:trip_id/notes (Add Note)

**Request:**
- **Method:** `POST`
- **Path:** `/trips/:trip_id/notes`
- **Headers:**
  - `Accept: text/vnd.turbo-stream.html` (for Turbo Stream response)
  - Session cookie
  - CSRF token
- **Body:**
```json
{
  "note": {
    "content": "Visit Louvre Museum"
  }
}
```

**Response (201 Created):**
- Turbo Stream response updating notes list and clearing form

**Error Response (422 Unprocessable Content):**
- Turbo Stream response displaying validation errors inline

### POST /trips/:trip_id/generated_plans (Generate Plan)

**Request:**
- **Method:** `POST`
- **Path:** `/trips/:trip_id/generated_plans`
- **Headers:**
  - `Accept: text/vnd.turbo-stream.html`
  - Session cookie
  - CSRF token
- **Body:** (optional)
```json
{
  "generated_plan": {
    "options": {}
  }
}
```

**Response (202 Accepted):**
- Turbo Stream response adding new plan to list with status 'pending' or 'generating'
- Subsequent status updates pushed via Turbo Streams as generation progresses

## 8. User Interactions

### Tab Navigation

**Interaction:** User clicks on "Notes" or "Generated Plans" tab button

**Expected Outcome:**
1. Active tab button receives `aria-selected="true"` and active styling
2. Inactive tab button receives `aria-selected="false"` and inactive styling
3. Active tab panel is shown (display: block or visible)
4. Inactive tab panel is hidden (display: none or hidden)
5. Smooth transition animation (optional, CSS-based)
6. URL hash may update to reflect active tab (optional, e.g., `/trips/1#notes`)

**Implementation:** Handled by Stimulus tabs controller with `switchTab()` action

### Add Note

**Interaction:** User fills out note form and clicks submit button

**Expected Outcome:**
1. Form validates client-side (if implemented) and shows errors immediately
2. Form submits via Turbo POST request to `/trips/:trip_id/notes`
3. Loading indicator appears (optional, via Turbo request loading state)
4. On success (201 Created):
   - New note appears in notes list (via Turbo Stream update)
   - Form clears and resets
   - Success message displayed (optional flash or inline message)
5. On validation error (422):
   - Form re-renders with inline error messages
   - User input preserved
   - Error messages displayed near form field

**Implementation:** Uses `form_with` with Turbo, server responds with Turbo Stream

### Generate Plan

**Interaction:** User clicks "Generate Plan" button

**Expected Outcome:**
1. Button shows loading state (disabled, spinner icon)
2. POST request sent to `/trips/:trip_id/generated_plans`
3. New generated plan appears in list with status 'pending' or 'generating' (via Turbo Stream)
4. Status chip shows appropriate color (yellow/gray for pending, blue for generating)
5. Button re-enables (or remains disabled if rate limiting applies)
6. As generation progresses:
   - Server pushes Turbo Stream updates when status changes
   - Status chip updates color (green for completed, red for failed)
   - Plan becomes viewable when status is 'completed'
7. If rate limit exceeded (429):
   - Error message displayed (flash or inline)
   - Button remains enabled
8. If user preferences missing (422):
   - Error message displayed
   - Link to preferences page shown (optional)

**Implementation:** `button_to` with Turbo, server responds with Turbo Stream, background job updates status and pushes updates

### Delete Trip

**Interaction:** User clicks "Delete Trip" button

**Expected Outcome:**
1. Browser confirmation dialog appears (via `data-turbo-confirm` attribute)
2. If user confirms:
   - DELETE request sent to `/trips/:id`
   - Loading state shown (optional)
   - On success (200 OK):
     - User redirected to trips index page (`/trips`)
     - Success flash message displayed: "Trip deleted successfully"
   - On error (404):
     - Error message displayed (flash or inline)
     - User remains on current page
3. If user cancels:
   - No action taken
   - Dialog closes
   - User remains on current page

**Implementation:** `button_to` with `method: :delete` and `data: { turbo_confirm: 'Are you sure you want to delete this trip? This action cannot be undone.' }`

### View Plan Details (Future - US-016)

**Interaction:** User clicks on a completed generated plan item or "View Plan" link

**Expected Outcome:**
1. Navigate to plan detail view (route: `/trips/:trip_id/generated_plans/:id` or modal)
2. Plan content displayed in organized format:
   - Summary with total cost, cost per person, duration
   - Daily itinerary with activities and restaurants
   - Each activity shows: time, name, duration, cost, rating
   - Each restaurant shows: meal type, name, cuisine, cost per person, rating
3. Rating widget displayed for user to rate plan (1-10 scale)
4. Rating submission updates plan via PATCH request

**Implementation:** Separate view or modal (implementation plan for US-016)

## 9. Conditions and Validation

### View-Level Conditions

**Trip Existence:**
- **Condition:** Trip must exist and belong to current user
- **Verification:** Controller checks via `current_user.trips.find(params[:id])`
- **Error Handling:** Returns 404 Not Found if trip not found or unauthorized
- **UI Impact:** Entire view not rendered, 404 page displayed

**User Authentication:**
- **Condition:** User must be authenticated
- **Verification:** `before_action :authenticate_user!` in controller
- **Error Handling:** Redirects to login page for HTML, returns 401 for JSON
- **UI Impact:** User redirected before view loads

### Component-Level Conditions

**Active Tab:**
- **Condition:** One tab must be active at a time
- **Verification:** Stimulus controller manages `activeTab` state
- **Validation:** Initial state defaults to 'notes' tab
- **UI Impact:** Only active tab panel is visible, corresponding tab button has active styling

**Notes List:**
- **Condition:** Display notes if any exist, show empty state otherwise
- **Verification:** Check `@trip.notes.any?` in partial
- **UI Impact:** Renders notes list or empty state message

**Generated Plans List:**
- **Condition:** Display plans if any exist, show empty state otherwise
- **Verification:** Check `@trip.generated_plans.any?` in partial
- **UI Impact:** Renders plans list or empty state message

**Plan Generation Button:**
- **Condition:** Button may be disabled if rate limit reached or generation in progress
- **Verification:** Server-side rate limiting, client-side disabled state
- **UI Impact:** Button shows disabled state, tooltip or message explains why

### Form Validation (Add Note Form)

**Server-Side Validation (Required):**
- **Content presence:** Content must be present (`validates :content, presence: true`)
- **Content not blank:** Content cannot be blank after whitespace removal
- **Content length:** Maximum 10,000 characters (`validates :content, length: { maximum: 10000 }`)
- **Trip existence:** Trip must exist and belong to user (enforced by controller)

**Client-Side Validation (Optional Enhancement):**
- **Content presence:** Check if content is empty before submission
- **Content length:** Check if content exceeds 10,000 characters
- **Immediate feedback:** Display error messages before form submission

**Validation Error Display:**
- Errors displayed inline near form field via Turbo Stream
- Error messages use Rails `errors.full_messages` format
- Form input preserved (user doesn't lose entered text)

### Status-Based Display Conditions (Generated Plans)

**Status Chip Colors:**
- `pending`: Gray or yellow chip
- `generating`: Blue chip (may include spinner/loading indicator)
- `completed`: Green chip
- `failed`: Red chip

**Rating Display:**
- **Condition:** Rating only displayed if plan status is 'completed' and rating is present
- **Verification:** Check `plan.status == 'completed' && plan.rating.present?`
- **UI Impact:** Rating widget or display shown only when applicable

**View Plan Link:**
- **Condition:** Link only enabled/visible if plan status is 'completed'
- **Verification:** Check `plan.status == 'completed'`
- **UI Impact:** Link displayed for completed plans, disabled or hidden for others

## 10. Error Handling

### View Load Errors

**404 Not Found (Trip Not Found):**
- **Scenario:** Trip ID doesn't exist or doesn't belong to user
- **Handling:** Controller raises `ActiveRecord::RecordNotFound`, handled by `rescue_from` in `ApplicationController`
- **Response:** 404 error page rendered (standard Rails 404 page or custom error page)
- **User Experience:** User sees error page, can navigate back to trips list

**401 Unauthorized (Not Authenticated):**
- **Scenario:** User not logged in
- **Handling:** Devise `before_action :authenticate_user!` intercepts request
- **Response:** Redirect to login page with flash message
- **User Experience:** User redirected to login, can return to trip after authentication

**500 Internal Server Error:**
- **Scenario:** Unexpected server error (database failure, etc.)
- **Handling:** Rails error handling, logged to error tracking service
- **Response:** 500 error page rendered
- **User Experience:** User sees error page, can report issue or retry

### Form Submission Errors

**Add Note Validation Errors (422):**
- **Scenario:** Note content validation fails (blank, too long, etc.)
- **Handling:** Controller returns 422 with error details, Turbo Stream updates form
- **Response:** Turbo Stream with error messages rendered inline
- **User Experience:** Form displays inline errors, user input preserved, user can correct and resubmit

**Add Note Trip Not Found (404):**
- **Scenario:** Trip deleted or doesn't exist when note form submitted
- **Handling:** Controller raises `ActiveRecord::RecordNotFound`
- **Response:** 404 error or redirect to trips list
- **User Experience:** Error message displayed, user redirected or can navigate back

### Plan Generation Errors

**Rate Limit Exceeded (429):**
- **Scenario:** User exceeded generation rate limits (5 per hour, 50 per day)
- **Handling:** Controller checks rate limits, returns 429 status
- **Response:** Error message displayed (flash or inline)
- **User Experience:** Error message explains rate limit, button remains visible but disabled temporarily, user can try again later

**User Preferences Missing (422):**
- **Scenario:** User attempts to generate plan without setting preferences
- **Handling:** Controller validates preferences existence, returns 422
- **Response:** Error message with link to preferences page
- **User Experience:** Clear error message, call-to-action to set preferences

**Plan Generation Failure:**
- **Scenario:** AI generation job fails (API error, timeout, etc.)
- **Handling:** Background job catches error, updates plan status to 'failed'
- **Response:** Turbo Stream updates plan status chip to 'failed' (red)
- **User Experience:** Plan shows failed status, user can attempt to generate new plan

**Network Errors:**
- **Scenario:** Request fails due to network issues
- **Handling:** Turbo/Fetch error handling, retry mechanism (optional)
- **Response:** Error message or automatic retry
- **User Experience:** Error message displayed, user can retry manually

### Delete Trip Errors

**404 Not Found:**
- **Scenario:** Trip already deleted or doesn't belong to user
- **Handling:** Controller raises `ActiveRecord::RecordNotFound`
- **Response:** 404 error or redirect
- **User Experience:** Error message displayed, user can navigate to trips list

**500 Internal Server Error:**
- **Scenario:** Database error during deletion
- **Handling:** Rails error handling
- **Response:** 500 error page or flash error message
- **User Experience:** Error message displayed, trip not deleted, user can retry

## 11. Implementation Steps

1. **Create Main View File**
   - Create `app/views/trips/show.html.erb`
   - Add page header using `render 'shared/page_header'`
   - Add container structure for trip header and tabs

2. **Implement Trip Header Partial**
   - Create `app/views/trips/_trip_header.html.erb`
   - Display trip name, destination, dates, and number of people
   - Add Edit button linking to `edit_trip_path(@trip)`
   - Add Delete button with `button_to` and `data-turbo-confirm` for confirmation
   - Style with Material Design Tailwind classes

3. **Implement Tab Navigation Component**
   - Create `app/views/trips/_tab_navigation.html.erb`
   - Add tab list with ARIA roles (`role="tablist"`, `role="tab"`)
   - Add two tab buttons: "Notes" and "Generated Plans"
   - Add tab panels with ARIA attributes (`role="tabpanel"`, `aria-labelledby`)
   - Create Stimulus controller (`app/javascript/controllers/tabs_controller.js`)
   - Implement tab switching logic, ARIA attribute updates, keyboard navigation
   - Style tabs with Material Design Tailwind classes

4. **Implement Notes Tab Content**
   - Create `app/views/trips/_notes_tab.html.erb`
   - Create `app/views/trips/_notes_list.html.erb` to render notes list or empty state
   - Create `app/views/trips/_note_item.html.erb` to display individual notes
   - Create `app/views/trips/_add_note_form.html.erb` with form for adding notes
   - Use `form_with` with Turbo for form submission
   - Add error message containers for validation errors
   - Style with Material Design Tailwind classes

5. **Implement Generated Plans Tab Content**
   - Create `app/views/trips/_generated_plans_tab.html.erb`
   - Add "Generate Plan" button with `button_to` POST to `/trips/:trip_id/generated_plans`
   - Create `app/views/trips/_generated_plans_list.html.erb` to render plans list or empty state
   - Create `app/views/trips/_generated_plan_item.html.erb` to display individual plans
   - Implement status chips with Material Design styling and color coding
   - Add rating display (if rating present)
   - Add view plan link (for future US-016 implementation)

6. **Implement Turbo Stream Responses**
   - Create Turbo Stream templates for note creation (`app/views/trips/notes/create.turbo_stream.erb`)
   - Create Turbo Stream templates for plan generation (`app/views/trips/generated_plans/create.turbo_stream.erb`)
   - Implement Turbo Stream updates for plan status changes (from background job)
   - Test real-time updates for plan generation status

7. **Add Stimulus Controller for Tabs**
   - Create `app/javascript/controllers/tabs_controller.js`
   - Implement `connect()` method to initialize tab state
   - Implement `switchTab(event)` method to handle tab switching
   - Implement keyboard navigation (Arrow keys, Enter/Space)
   - Update ARIA attributes dynamically
   - Handle URL hash updates (optional)

8. **Style Components with Material Tailwind**
   - Apply Material Design card styles to trip header
   - Style tab navigation with Material Design tab component styles
   - Style notes and plans lists with Material Design list/card styles
   - Apply status chip colors (pending: gray/yellow, generating: blue, completed: green, failed: red)
   - Ensure responsive design (mobile-first approach)
   - Add loading states and transitions

9. **Implement Empty States**
   - Add empty state message for notes list ("No notes yet. Add your first note below.")
   - Add empty state message for generated plans list ("No generated plans yet. Click 'Generate Plan' to create your first plan.")
   - Style empty states with appropriate messaging and optional call-to-action

10. **Test Error Handling**
    - Test 404 error when trip not found
    - Test 401 error when not authenticated
    - Test form validation errors (blank content, too long)
    - Test rate limiting error messages
    - Test delete confirmation dialog
    - Test network error scenarios

11. **Accessibility Testing**
    - Verify ARIA roles and attributes are correct
    - Test keyboard navigation for tabs
    - Verify screen reader compatibility
    - Test focus management when switching tabs
    - Ensure all interactive elements have appropriate labels

12. **Integration Testing**
    - Test complete flow: view trip → add note → generate plan → delete trip
    - Test real-time updates via Turbo Streams
    - Test tab persistence (if URL hash used)
    - Test responsive design on mobile and desktop
    - Verify Material Design components render correctly

