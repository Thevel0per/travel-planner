# View Implementation Plan: New/Edit Trip Form

## 1. Overview

The New/Edit Trip Form view allows users to create new trips or update existing trip details. This view serves a dual purpose: displaying an empty form for new trip creation (`GET /trips/new`) and a pre-populated form for editing existing trips (`GET /trips/:id/edit`). The form collects essential trip information including trip name, destination, start date, end date, and number of people. It implements Material Design principles using Material Tailwind CSS and handles validation errors gracefully using Turbo Streams to preserve user input and display inline error messages without requiring a full page reload.

**Note:** This implementation plan uses **generalized, reusable form components** located in `app/views/shared/` that can be reused across the entire application. The trip form serves as a specific implementation example using these shared components.

## 2. View Routing

- **New Trip Form:** `GET /trips/new` (route: `new_trip_path`)
- **Edit Trip Form:** `GET /trips/:id/edit` (route: `edit_trip_path(trip)`)

Both routes are protected by `authenticate_user!` before_action in the controller, ensuring only authenticated users can access the forms.

## 3. Component Structure

```
TripFormView (Main Container)
├── PageHeader (reusable)
│   ├── Title (h1)
│   └── Description (p)
├── SharedForm (reusable form wrapper)
│   ├── FormField (reusable, name)
│   │   ├── Label
│   │   ├── Text Input
│   │   └── ErrorMessage (conditional)
│   ├── FormField (reusable, destination)
│   │   ├── Label
│   │   ├── Text Input
│   │   └── ErrorMessage (conditional)
│   ├── FormField (reusable, start_date)
│   │   ├── Label
│   │   ├── Date Input
│   │   └── ErrorMessage (conditional)
│   ├── FormField (reusable, end_date)
│   │   ├── Label
│   │   ├── Date Input
│   │   └── ErrorMessage (conditional)
│   ├── FormField (reusable, number_of_people)
│   │   ├── Label
│   │   ├── Number Input
│   │   └── ErrorMessage (conditional)
│   └── FormActions (reusable)
│       ├── Submit Button
│       └── Cancel Button (link)
```

**Reusable Component Locations:**
- `app/views/shared/_page_header.html.erb` - Generic page header component
- `app/views/shared/_form.html.erb` - Generic form wrapper component
- `app/views/shared/_form_field.html.erb` - Reusable form field component
- `app/views/shared/_error_message.html.erb` - Reusable error message component
- `app/views/shared/_form_actions.html.erb` - Reusable form actions component
- `app/views/trips/_form.html.erb` - Trip-specific form configuration (uses shared components)

## 4. Component Details

### TripFormView (Main Container)

- **Component description:** The root container component that wraps the entire form view. Provides consistent page structure and Material Design styling context using the `material-tailwind` Stimulus controller.

- **Main elements:**
  - `<div>` with `data-controller="material-tailwind"` attribute for Material Tailwind initialization
  - Container div with Material Design spacing and max-width constraints
  - Semantic `<main>` element containing the form content

- **Handled interactions:** None (container only)

- **Handled validation:** None (delegated to form fields)

- **Types:** None (view-level component)

- **Props:** None (receives `@trip` from controller for edit mode, `nil` for new mode)

### PageHeader (Reusable Component)

- **Component description:** A reusable component that displays page titles and optional descriptions. Can be used across the application for consistent page header styling. Located at `app/views/shared/_page_header.html.erb`.

- **Main elements:**
  - `<h1>` element with Material Design typography classes for the title
  - `<p>` element with Material Design typography classes for optional description

- **Handled interactions:** None (static content)

- **Handled validation:** None

- **Types:** None (generic string props)

- **Props:**
  - `title` (String, required): The main page title text
  - `description` (String, optional): Optional description text displayed below the title
  - `css_classes` (String, optional): Additional CSS classes to apply to the container

### SharedForm (Reusable Form Wrapper)

- **Component description:** A reusable form wrapper component located at `app/views/shared/_form.html.erb`. Provides consistent form structure, Turbo integration, and CSRF token handling. Can be used for any form in the application.

- **Main elements:**
  - `<form>` element with Turbo attributes (`data-turbo="true"`)
  - Material Design form styling classes
  - CSRF token hidden field (`<%= form_authenticity_token %>`)
  - Yield block for form fields content

- **Handled interactions:**
  - Form submission (`submit` event): Intercepted by Turbo, submits via AJAX with configurable method and action

- **Handled validation:**
  - Client-side HTML5 validation (required fields, date format, number ranges)
  - Server-side validation errors displayed via Turbo Stream responses

- **Types:**
  - Generic - accepts any model or form data structure
  - Error response type: `ErrorResponseDTO` on validation failure (422 Unprocessable Content)

- **Props:**
  - `model` (ActiveRecord model or nil): Model instance for edit mode, nil for new mode (generic, not trip-specific)
  - `url` (String, required): Form action URL (e.g., `trips_path` for new, `trip_path(@trip)` for edit)
  - `method` (String, required): HTTP method (`POST`, `PATCH`, `PUT`, etc.)
  - `html_options` (Hash, optional): Additional HTML attributes for the form element (e.g., `{ class: "custom-class" }`)
  - `local` (Boolean, optional, default: false): Whether to disable Turbo (set to `true` for non-Turbo forms)

### FormField (Reusable Component)

- **Component description:** A fully reusable form field component located at `app/views/shared/_form_field.html.erb`. Groups a label, input field, and error message for any form field. Can be used across the application for consistent form field styling and behavior.

- **Main elements:**
  - Container `<div>` with Material Design spacing
  - `<label>` element with `for` attribute linking to input `id`
  - `<input>` or `<textarea>` or `<select>` element (type/configurable)
  - Error message container (rendered via `_error_message` partial, conditionally rendered when errors exist)

- **Handled interactions:**
  - Input value change (`input`, `change` events): Updates form field value
  - Input blur (`blur` event): Optional client-side validation feedback
  - Input focus (`focus` event): Clears error display if previously shown (optional Stimulus enhancement)

- **Handled validation:**
  - Generic validation support - accepts any validation rules via props
  - HTML5 validation attributes applied based on props (`required`, `min`, `max`, `maxlength`, etc.)
  - Server-side validation errors displayed via ErrorMessage component

- **Types:**
  - Input value type: String, Integer, Float, or Date (depends on field type)
  - Error type: `Array<String>` (array of error messages for the field)
  - Model errors: ActiveModel::Errors (extracted via `model.errors[field_name]`)

- **Props:**
  - `form` (FormBuilder, required): Rails form builder object (e.g., from `form_with`)
  - `field_name` (Symbol or String, required): Name of the field (e.g., `:name`, `:destination`)
  - `field_type` (String, required): HTML input type ("text", "email", "date", "number", "password", "textarea", "select", etc.)
  - `label` (String, optional): Display text for the label (defaults to `field_name.humanize` if not provided)
  - `model` (ActiveRecord model, optional): Model instance for extracting current value and errors (if using form builder with model, can be inferred)
  - `required` (Boolean, optional, default: false): Whether the field is required
  - `errors` (Array<String>, optional): Array of error messages (if not provided, extracted from `model.errors[field_name]`)
  - `value` (String/Integer/Float, optional): Current value of the input (if not provided, extracted from model)
  - `placeholder` (String, optional): Placeholder text for the input
  - `min` (String/Number, optional): Minimum value (for dates/numbers)
  - `max` (String/Number, optional): Maximum value (for dates/numbers)
  - `maxlength` (Integer, optional): Maximum character length (for text inputs)
  - `step` (String/Number, optional): Step value for number inputs
  - `css_classes` (String, optional): Additional CSS classes for the field container
  - `input_options` (Hash, optional): Additional HTML attributes for the input element (e.g., `{ disabled: true, readonly: true }`)
  - `select_options` (Array/Proc, optional): Options for select fields (array of arrays `[label, value]` or Proc that returns options)
  - `textarea_rows` (Integer, optional): Number of rows for textarea fields (default: 3)

### ErrorMessage (Reusable Component)

- **Component description:** A reusable error message component located at `app/views/shared/_error_message.html.erb`. Displays validation error messages for any form field with Material Design styling. Conditionally rendered only when errors exist.

- **Main elements:**
  - `<div>` container with Material Design error styling (red text, error icon)
  - `<span>` or `<p>` elements displaying error messages (one per error message)
  - Optional error icon (SVG or icon font)

- **Handled interactions:** None (display only)

- **Handled validation:** None (displays validation results)

- **Types:**
  - Error messages type: `Array<String>` (list of error messages)

- **Props:**
  - `errors` (Array<String>, required): Array of error messages to display (renders all messages)
  - `field_id` (String, optional): ID of the associated input field for ARIA `aria-describedby` attribute
  - `css_classes` (String, optional): Additional CSS classes for the error container
  - `show_icon` (Boolean, optional, default: true): Whether to display an error icon

### FormActions (Reusable Component)

- **Component description:** A reusable form actions component located at `app/views/shared/_form_actions.html.erb`. Container for form action buttons (submit and cancel) with Material Design styling. Can be used across all forms in the application.

- **Main elements:**
  - Container `<div>` with flexbox layout for button alignment
  - Submit button (`<button type="submit">`) with Material Design primary button styling
  - Cancel link (`<%= link_to %>`) styled as secondary button/link (optional)

- **Handled interactions:**
  - Submit button click: Triggers form submission (handled by parent form)
  - Cancel link click: Navigates to specified cancel path

- **Handled validation:** None (actions only)

- **Types:** None (generic component)

- **Props:**
  - `submit_text` (String, required): Text for submit button (e.g., "Create Trip", "Update Trip", "Save Changes")
  - `submit_class` (String, optional): Additional CSS classes for submit button (default: Material Design primary button classes)
  - `cancel_text` (String, optional): Text for cancel link (default: "Cancel")
  - `cancel_path` (String, optional): Path to navigate to on cancel (if not provided, cancel button is hidden)
  - `cancel_class` (String, optional): Additional CSS classes for cancel link (default: Material Design secondary button/link classes)
  - `is_loading` (Boolean, optional, default: false): Whether form is currently submitting (disables submit button and shows loading state)
  - `loading_text` (String, optional): Text to display on submit button during loading (default: "Saving...")
  - `css_classes` (String, optional): Additional CSS classes for the actions container

## 5. Types

### TripFormRequest (ViewModel)

A ViewModel type representing the form data structure sent to the server:

```typescript
interface TripFormRequest {
  trip: {
    name: string;              // Required, max 255 characters
    destination: string;      // Required, max 255 characters
    start_date: string;        // Required, ISO 8601 date format (YYYY-MM-DD)
    end_date: string;          // Required, ISO 8601 date format (YYYY-MM-DD)
    number_of_people: number;  // Required, integer >= 1, default: 1
  };
}
```

**Field Details:**
- `trip.name` (String): Trip name/title. Required, maximum 255 characters.
- `trip.destination` (String): Destination location. Required, maximum 255 characters.
- `trip.start_date` (String): Start date in ISO 8601 format (YYYY-MM-DD). Required, must be a valid date.
- `trip.end_date` (String): End date in ISO 8601 format (YYYY-MM-DD). Required, must be a valid date and must be after `start_date`.
- `trip.number_of_people` (Integer): Number of people in the travel group. Required, must be an integer greater than 0, default value: 1.

### TripDTO (Response Type)

The response type for successful form submission. Full structure as defined in `app/types/dtos/trip_dto.rb`:

```ruby
# Core attributes
id: Integer
name: String
destination: String
start_date: String  # ISO 8601 date format (YYYY-MM-DD)
end_date: String    # ISO 8601 date format (YYYY-MM-DD)
number_of_people: Integer
created_at: String  # ISO 8601 datetime format
updated_at: String  # ISO 8601 datetime format
```

### ErrorResponseDTO (Error Response Type)

The error response type for validation failures (422 Unprocessable Content):

```ruby
# Structure
errors: {
  "field_name" => ["error message 1", "error message 2"]
}
```

**Field Details:**
- `errors` (Hash<String, Array<String>>): Hash where keys are field names (as strings) and values are arrays of error messages for that field.
- Possible error fields: `"name"`, `"destination"`, `"start_date"`, `"end_date"`, `"number_of_people"`.
- Common error messages:
  - `"name"`: `["can't be blank"]`
  - `"destination"`: `["can't be blank"]`
  - `"start_date"`: `["can't be blank"]`
  - `"end_date"`: `["can't be blank"]`, `["must be after start date"]`
  - `"number_of_people"`: `["can't be blank"]`, `["must be greater than 0"]`

## 6. State Management

The form view uses a simple, server-driven state management approach consistent with Rails and Hotwire patterns:

1. **Initial State:**
   - For new trip: All form fields are empty (or set to defaults: `number_of_people = 1`).
   - For edit trip: Form fields are pre-populated from the `@trip` model instance passed from the controller.

2. **Form Input State:**
   - Form field values are managed by standard HTML form inputs (uncontrolled components in React terminology).
   - Values are preserved automatically by the browser and Turbo during form re-renders.

3. **Error State:**
   - Initially: No errors displayed.
   - After validation failure: Error messages are injected into the DOM via Turbo Stream responses from the server.
   - Error state is cleared when:
     - User successfully submits the form
     - User navigates away from the form
     - Form is re-rendered by server with updated state

4. **Loading State:**
   - Submit button can be disabled during form submission using a Stimulus controller or simple JavaScript.
   - Loading indicator (optional) can be shown during submission.

5. **Custom Hooks:**
   - **No custom React/Stimulus hooks required** for basic functionality. The form uses standard Rails form helpers and Turbo for submission.
   - **Optional Enhancement:** A Stimulus controller (`trip-form-controller.js`) could be added to:
     - Disable submit button during submission
     - Add real-time client-side validation feedback
     - Dynamically update `end_date` minimum value when `start_date` changes
     - Handle form reset on success

## 7. API Integration

### Create Trip (New Form)

**Endpoint:** `POST /trips`

**Request:**
- Method: `POST`
- URL: `/trips`
- Headers:
  - `Content-Type: application/x-www-form-urlencoded` (HTML form submission)
  - `X-CSRF-Token: <authenticity_token>` (Rails CSRF protection)
  - `Accept: text/html` or `text/vnd.turbo-stream.html` (for Turbo Stream responses)
- Body (form data):
  ```
  trip[name]=Summer Vacation 2025
  trip[destination]=Paris, France
  trip[start_date]=2025-07-15
  trip[end_date]=2025-07-22
  trip[number_of_people]=2
  ```

**Success Response (201 Created):**
- Status: `201 Created`
- Content-Type: `text/html`
- Body: Redirect to `/trips/:id` with flash message `flash[:notice] = 'Trip created successfully'`
- Turbo: Handles redirect automatically

**Error Response (422 Unprocessable Content):**
- Status: `422 Unprocessable Content`
- Content-Type: `text/vnd.turbo-stream.html` (Turbo Stream) or `text/html`
- Body: Turbo Stream response that updates the form with inline error messages
- Error format: Rails form with `@trip.errors` populated, rendered as partial

### Update Trip (Edit Form)

**Endpoint:** `PUT/PATCH /trips/:id`

**Request:**
- Method: `PATCH` (Rails prefers PATCH over PUT)
- URL: `/trips/:id`
- Headers:
  - `Content-Type: application/x-www-form-urlencoded`
  - `X-CSRF-Token: <authenticity_token>`
  - `Accept: text/html` or `text/vnd.turbo-stream.html`
- Body (form data, all fields optional for partial updates):
  ```
  trip[name]=Updated Summer Vacation 2025
  trip[destination]=Paris, France
  trip[start_date]=2025-07-16
  trip[end_date]=2025-07-23
  trip[number_of_people]=3
  ```
- Additional: `_method=PATCH` hidden field (for HTML form compatibility)

**Success Response (200 OK):**
- Status: `200 OK`
- Content-Type: `text/html`
- Body: Redirect to `/trips/:id` with flash message `flash[:notice] = 'Trip updated successfully'`

**Error Response (422 Unprocessable Content):**
- Status: `422 Unprocessable Content`
- Content-Type: `text/vnd.turbo-stream.html` or `text/html`
- Body: Turbo Stream response with form re-rendered and error messages
- Error format: Same as create endpoint

**Error Response (404 Not Found):**
- Status: `404 Not Found`
- Content-Type: `text/html`
- Body: Redirect to trips list with flash message (handled by `ApplicationController#handle_not_found`)

## 8. User Interactions

### 8.1. Creating a New Trip

1. **Navigate to Form:**
   - User clicks "Create Trip" button (FAB on trips list or link in navigation)
   - Action: `GET /trips/new`
   - Result: Form page loads with empty fields

2. **Fill Form Fields:**
   - User enters trip name, destination, dates, and number of people
   - Action: Input events on form fields
   - Result: Form values update in real-time (standard HTML form behavior)

3. **Submit Form:**
   - User clicks "Create Trip" button
   - Action: Form submission via Turbo (`POST /trips`)
   - Validation: Client-side HTML5 validation runs first
   - Success Result (201): Redirect to trip detail page (`/trips/:id`) with success flash message
   - Error Result (422): Form re-renders with inline error messages via Turbo Stream, user input preserved

4. **Cancel:**
   - User clicks "Cancel" link
   - Action: Navigation to `/trips` (trips list)
   - Result: Form data is discarded, user returns to trips list

### 8.2. Editing an Existing Trip

1. **Navigate to Form:**
   - User clicks "Edit" button/link on trip detail page
   - Action: `GET /trips/:id/edit`
   - Result: Form page loads with fields pre-populated from existing trip data

2. **Modify Form Fields:**
   - User changes one or more fields (all fields optional for partial updates)
   - Action: Input events on form fields
   - Result: Form values update in real-time

3. **Submit Form:**
   - User clicks "Update Trip" button
   - Action: Form submission via Turbo (`PATCH /trips/:id`)
   - Validation: Client-side HTML5 validation runs first
   - Success Result (200): Redirect to trip detail page with success flash message
   - Error Result (422): Form re-renders with inline error messages, user input preserved

4. **Cancel:**
   - User clicks "Cancel" link
   - Action: Navigation to `/trips/:id` (trip detail page)
   - Result: Changes are discarded, user returns to trip detail view

### 8.3. Date Field Interaction

1. **Start Date Change:**
   - User selects or changes start date
   - Action: `change` event on start_date input
   - Expected Behavior: End date minimum value updates dynamically (if implemented via Stimulus)
   - Validation: If end_date is already set and is before new start_date, show warning or clear end_date

2. **End Date Selection:**
   - User selects end date
   - Action: `change` event on end_date input
   - Validation: Browser enforces minimum date (must be after start_date if start_date is set)

### 8.4. Number of People Input

1. **Change Value:**
   - User increments/decrements or types number
   - Action: `input` or `change` event on number input
   - Validation: Browser enforces minimum value of 1 (via `min="1"` attribute)

## 9. Conditions and Validation

### 9.1. Client-Side Validation (HTML5)

**Field: name**
- Condition: Required (`required` attribute)
- Condition: Maximum length 255 characters (`maxlength="255"` attribute)
- Component: FormFieldGroup for name
- Effect: Browser shows validation message if empty on submit

**Field: destination**
- Condition: Required (`required` attribute)
- Condition: Maximum length 255 characters (`maxlength="255"` attribute)
- Component: FormFieldGroup for destination
- Effect: Browser shows validation message if empty on submit

**Field: start_date**
- Condition: Required (`required` attribute)
- Condition: Valid date format (YYYY-MM-DD) enforced by `type="date"` input
- Component: FormFieldGroup for start_date
- Effect: Browser date picker ensures valid date format

**Field: end_date**
- Condition: Required (`required` attribute)
- Condition: Valid date format (YYYY-MM-DD) enforced by `type="date"` input
- Condition: Must be after start_date (enforced via `min` attribute, dynamically updated via JavaScript/Stimulus)
- Component: FormFieldGroup for end_date
- Effect: Browser date picker restricts selection to dates after start_date

**Field: number_of_people**
- Condition: Required (`required` attribute)
- Condition: Must be integer (`type="number"` input)
- Condition: Must be greater than 0 (`min="1"` attribute)
- Condition: Default value: 1
- Component: FormFieldGroup for number_of_people
- Effect: Browser shows validation message if value is 0 or negative

### 9.2. Server-Side Validation (API Requirements)

**Field: name**
- Condition: Presence validation (`validates :name, presence: true`)
- Condition: Length validation (`validates :name, length: { maximum: 255 }`)
- Error Message: `"name": ["can't be blank"]` if missing
- Component: FormFieldGroup displays error via ErrorMessage component
- Effect: Form re-renders with error message below name input

**Field: destination**
- Condition: Presence validation (`validates :destination, presence: true`)
- Condition: Length validation (`validates :destination, length: { maximum: 255 }`)
- Error Message: `"destination": ["can't be blank"]` if missing
- Component: FormFieldGroup displays error via ErrorMessage component
- Effect: Form re-renders with error message below destination input

**Field: start_date**
- Condition: Presence validation (`validates :start_date, presence: true`)
- Error Message: `"start_date": ["can't be blank"]` if missing
- Component: FormFieldGroup displays error via ErrorMessage component
- Effect: Form re-renders with error message below start_date input

**Field: end_date**
- Condition: Presence validation (`validates :end_date, presence: true`)
- Condition: Custom validation (`validate :end_date_after_start_date`)
- Error Message: `"end_date": ["can't be blank"]` if missing
- Error Message: `"end_date": ["must be after start date"]` if end_date <= start_date
- Component: FormFieldGroup displays error via ErrorMessage component
- Effect: Form re-renders with error message below end_date input

**Field: number_of_people**
- Condition: Presence validation (`validates :number_of_people, presence: true`)
- Condition: Numericality validation (`validates :number_of_people, numericality: { only_integer: true, greater_than: 0 }`)
- Error Message: `"number_of_people": ["can't be blank"]` if missing
- Error Message: `"number_of_people": ["must be greater than 0"]` if invalid value
- Component: FormFieldGroup displays error via ErrorMessage component
- Effect: Form re-renders with error message below number_of_people input

### 9.3. Cross-Field Validation

**Condition: end_date must be after start_date**
- Verified by: Model validation (`end_date_after_start_date` method)
- Component: Affects both start_date and end_date FormFieldGroups
- Client-side: Enforced via `min` attribute on end_date input (updated dynamically)
- Server-side: Custom validation method in Trip model
- Effect: If validation fails, error message displayed on end_date field

### 9.4. Authentication and Authorization

**Condition: User must be authenticated**
- Verified by: `before_action :authenticate_user!` in TripsController
- Component: Entire view (handled at controller level)
- Effect: Unauthenticated users redirected to login page

**Condition: User can only edit their own trips**
- Verified by: `@trip = current_user.trips.find(params[:id])` in `set_trip` method
- Component: Edit form view (handled at controller level)
- Effect: 404 Not Found returned if trip doesn't belong to user

## 10. Error Handling

### 10.1. Validation Errors (422 Unprocessable Content)

**Scenario:** Server returns validation errors after form submission.

**Handling:**
1. Controller renders form with `@trip` model containing errors (via `trip.errors`)
2. Turbo Stream response updates form HTML with error messages
3. ErrorMessage components are rendered for each field with errors
4. User input is preserved (form values remain in inputs)
5. Inline error messages appear below each invalid field
6. Form remains on same page (no redirect), allowing user to correct errors and resubmit

**Implementation:**
- Controller action (create/update) responds with `status: :unprocessable_content`
- View renders form partial with errors displayed
- Turbo handles the update automatically (no custom JavaScript required)

### 10.2. Not Found Error (404)

**Scenario:** User attempts to edit a trip that doesn't exist or doesn't belong to them.

**Handling:**
1. Controller raises `ActiveRecord::RecordNotFound` exception
2. `ApplicationController#handle_not_found` rescues the exception
3. User redirected to trips list with flash message: "Resource not found"
4. Flash message displayed via toast/snackbar in layout

**Implementation:**
- Handled automatically by `rescue_from` in ApplicationController
- No view-level handling required

### 10.3. Network Errors

**Scenario:** Network failure or timeout during form submission.

**Handling:**
1. Turbo handles network errors gracefully
2. Browser may display default error message
3. Optional: Add Stimulus controller to show custom error toast
4. User can retry submission

**Implementation:**
- Can add Turbo error event listener in Stimulus controller if custom handling needed
- Default browser/Turbo behavior acceptable for MVP

### 10.4. Server Errors (500)

**Scenario:** Unexpected server error during form submission.

**Handling:**
1. Server returns 500 status code
2. ApplicationController error handler (if implemented) redirects with error message
3. User sees flash message: "An unexpected error occurred"
4. Form state is preserved (user can retry)

**Implementation:**
- Handled by ApplicationController error handling
- Flash message displayed via toast/snackbar

### 10.5. CSRF Token Errors

**Scenario:** CSRF token expired or invalid.

**Handling:**
1. Rails raises `ActionController::InvalidAuthenticityToken` exception
2. User redirected to login or shown error message
3. User must refresh page to get new CSRF token

**Implementation:**
- Handled automatically by Rails CSRF protection
- CSRF token included in form via `form_authenticity_token` helper

### 10.6. Multiple Validation Errors

**Scenario:** Multiple fields have validation errors.

**Handling:**
1. All error messages displayed simultaneously
2. Each FormFieldGroup shows its own ErrorMessage component
3. User can see all errors at once and correct them
4. Form remains functional, allowing correction of all fields

**Implementation:**
- Standard Rails error handling displays all model errors
- ErrorMessage components iterate over error array for each field

## 11. Implementation Steps

1. **Create Reusable Shared Components (Generalized):**
   - Create `app/views/shared/_page_header.html.erb` - Generic page header component
   - Create `app/views/shared/_form.html.erb` - Generic form wrapper component with Turbo support
   - Create `app/views/shared/_form_field.html.erb` - Reusable form field component supporting all input types
   - Create `app/views/shared/_error_message.html.erb` - Reusable error message component
   - Create `app/views/shared/_form_actions.html.erb` - Reusable form actions component

2. **Implement Reusable Page Header Component (`shared/_page_header.html.erb`):**
   - Accept `title` and optional `description` props
   - Apply Material Design typography classes
   - Ensure consistent styling across all pages

3. **Implement Reusable Form Wrapper (`shared/_form.html.erb`):**
   - Accept `model`, `url`, `method`, and optional `html_options` props
   - Add Turbo attributes (`data-turbo="true"`)
   - Include CSRF token hidden field
   - Use `form_with` helper with provided options
   - Yield block for form fields content
   - Apply Material Design form styling

4. **Implement Reusable Form Field Component (`shared/_form_field.html.erb`):**
   - Accept comprehensive props: `form`, `field_name`, `field_type`, `label`, `model`, validation attributes, etc.
   - Support all input types: text, email, date, number, password, textarea, select
   - Extract errors from model automatically if provided
   - Render label with proper `for` attribute
   - Render appropriate input type based on `field_type`
   - Conditionally render error messages via `_error_message` partial
   - Apply Material Design input styling

5. **Implement Reusable Error Message Component (`shared/_error_message.html.erb`):**
   - Accept `errors` array and optional `field_id` for ARIA attributes
   - Render all error messages with Material Design error styling (red text, error icon)
   - Support `aria-describedby` for accessibility
   - Conditionally render only when errors array is present and not empty

6. **Implement Reusable Form Actions Component (`shared/_form_actions.html.erb`):**
   - Accept `submit_text`, `cancel_path`, `cancel_text`, `is_loading`, etc.
   - Render submit button with Material Design primary button styling
   - Optionally render cancel link (if `cancel_path` provided) with secondary styling
   - Support loading state (disable submit button, show loading text)
   - Apply flexbox layout for button alignment

7. **Create Trip-Specific View Files:**
   - Create `app/views/trips/new.html.erb` for the new trip form view
   - Create `app/views/trips/edit.html.erb` for the edit trip form view
   - Create `app/views/trips/_form.html.erb` partial that uses shared components to configure trip-specific form

8. **Implement Trip Form Partial (`trips/_form.html.erb`):**
   - Use `render 'shared/form'` with trip-specific configuration:
     - `model: trip` (can be nil for new, `@trip` for edit)
     - `url: trip.persisted? ? trip_path(trip) : trips_path`
     - `method: trip.persisted? ? :patch : :post`
   - Use `render 'shared/form_field'` for each trip field:
     - Name field: `field_name: :name`, `field_type: 'text'`, `required: true`, `maxlength: 255`
     - Destination field: `field_name: :destination`, `field_type: 'text'`, `required: true`, `maxlength: 255`
     - Start date field: `field_name: :start_date`, `field_type: 'date'`, `required: true`
     - End date field: `field_name: :end_date`, `field_type: 'date'`, `required: true`, `min: trip.start_date` (if start_date exists)
     - Number of people field: `field_name: :number_of_people`, `field_type: 'number'`, `required: true`, `min: 1`
   - Use `render 'shared/form_actions'` with trip-specific text:
     - `submit_text: trip.persisted? ? 'Update Trip' : 'Create Trip'`
     - `cancel_path: trip.persisted? ? trip_path(trip) : trips_path`

9. **Implement New Trip View (`trips/new.html.erb`):**
   - Add main container with Material Tailwind controller (`data-controller="material-tailwind"`)
   - Use `render 'shared/page_header'` with `title: 'Create New Trip'`
   - Render `trips/_form` partial with `trip: nil`
   - Style with Material Design spacing and typography

10. **Implement Edit Trip View (`trips/edit.html.erb`):**
    - Add main container with Material Tailwind controller
    - Use `render 'shared/page_header'` with `title: 'Edit Trip'`
    - Render `trips/_form` partial with `trip: @trip`
    - Style with Material Design spacing and typography

11. **Implement Client-Side Validation Enhancement (Optional):**
    - Create generic Stimulus controller `app/javascript/controllers/form_controller.js` (not trip-specific)
    - Add functionality to:
      - Disable submit button during form submission (generic, works for any form)
      - Show/hide loading indicator
      - Dynamically update dependent field attributes (e.g., update `end_date` min when `start_date` changes)
    - Create trip-specific enhancement controller `app/javascript/controllers/trip_form_controller.js` if needed:
      - Extends or uses `form_controller.js`
      - Handles trip-specific logic (date dependencies)
    - Connect controller to form via `data-controller="form trip-form"` (use both if needed)

12. **Add Material Design Styling to Shared Components:**
    - Apply Material Tailwind CSS classes in shared form components:
      - Material Design input styles in `_form_field.html.erb`
      - Material Design button styles in `_form_actions.html.erb`
      - Material Design typography in `_page_header.html.erb`
      - Proper spacing and typography throughout
      - Ensure responsive design (mobile-first) in all shared components

13. **Test Form Submission:**
    - Test successful trip creation (redirects to trip detail page)
    - Test successful trip update (redirects to trip detail page)
    - Test validation errors (form re-renders with errors, shared components display correctly)
    - Test 404 error handling (edit non-existent trip)
    - Test authentication (access form without login)

14. **Implement Turbo Stream Error Response:**
    - Ensure controller renders form with errors on validation failure
    - Turbo automatically handles updating the form (if using `render :new` or `render :edit` with status 422)
    - Verify that user input is preserved in form fields after error response
    - Ensure shared error message component displays correctly in Turbo Stream responses

15. **Add Accessibility Features to Shared Components:**
    - Ensure `_form_field.html.erb` always includes associated `<label>` elements with `for` attributes
    - Add `aria-describedby` attributes in `_form_field.html.erb` linking inputs to error messages
    - Ensure `_error_message.html.erb` has proper ARIA roles and attributes
    - Test keyboard navigation through form fields
    - Ensure all shared components are accessible to screen readers

16. **Document Reusable Components:**
    - Create documentation file `app/views/shared/README.md` documenting:
      - Props for each shared component
      - Usage examples for different scenarios
      - Best practices for using shared components
    - Include trip form as an example usage

17. **Polish and Refinement:**
    - Review and adjust spacing and typography in shared components to match Material Design guidelines
    - Ensure all forms using shared components look consistent across the application
    - Test shared components with other forms (if any) to ensure reusability
    - Test trip form on multiple screen sizes (mobile, tablet, desktop)
    - Verify flash messages display correctly after successful submission
    - Ensure cancel button navigates to correct page (trips list for new, trip detail for edit)

