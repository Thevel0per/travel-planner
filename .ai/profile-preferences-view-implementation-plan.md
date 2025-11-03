# View Implementation Plan: Profile & Preferences

## 1. Overview

The Profile & Preferences view is a centralized settings page where users can manage both their account information and travel preferences. The view uses a tabbed interface to separate "Account" settings (managed by Devise) from "Preferences" settings (travel-related preferences managed by the application). The Preferences tab allows users to set or update their travel preferences including budget, accommodation type, activities, and eating habits. All preferences are optional and can be updated at any time. The view supports both creating new preferences (when none exist) and updating existing preferences via an upsert operation.

## 2. View Routing

**Primary Route:** `GET /profile` (custom route to be added to `config/routes.rb`)

**Controller Action:** Create a new `ProfilesController` with a `show` action that renders the profile view, or add a `show` action to an existing controller.

**Nested Routes:**
- Preferences endpoint: `GET /preferences` (already exists, returns preferences data)
- Preferences update: `PUT/PATCH /preferences` (already exists, upsert operation)
- Devise account routes: `edit_user_registration_path` (provided by Devise)

**URL Parameters:**
- `?tab=account` - Opens Account tab by default
- `?tab=preferences` - Opens Preferences tab by default (default if no parameter)
- `#account` or `#preferences` - Alternative hash-based tab selection (supported by tabs controller)

## 3. Component Structure

```
ProfileView (show.html.erb)
├── PageHeader Component
│   └── Title: "Profile & Preferences"
├── TabNavigation Component
│   ├── Tab List (ul with role="tablist")
│   │   ├── Account Tab Button
│   │   └── Preferences Tab Button
│   └── Tab Panels Container
│       ├── Account Tab Panel
│       │   └── AccountSettings Partial
│       └── Preferences Tab Panel
│           └── PreferencesForm Partial
│               ├── Form Wrapper (form_with)
│               ├── Budget FieldGroup
│               ├── Accommodation FieldGroup
│               ├── Activities FieldGroup (multi-select checkboxes)
│               ├── Eating Habits FieldGroup
│               └── Form Actions (submit, cancel)
```

## 4. Component Details

### ProfileView (show.html.erb)

- **Component description:** Main view file that renders the Profile & Preferences page. Contains the page header and tab navigation component. Acts as the container for all profile-related content.

- **Main elements:**
  - Container `<div>` with page layout styling (max-width, padding, margin)
  - PageHeader component (`render 'shared/page_header', title: 'Profile & Preferences'`)
  - TabNavigation component (`render 'profiles/tab_navigation', active_tab: @active_tab`)

- **Handled interactions:** None (delegated to child components)

- **Handled validation:** None (delegated to form components)

- **Types:** None (view template, receives `@active_tab` from controller)

- **Props:**
  - `@active_tab` (String, optional): Active tab identifier ('account' or 'preferences'), default: 'preferences'

### TabNavigation Component (_tab_navigation.html.erb)

- **Component description:** Reusable tab navigation component that manages switching between Account and Preferences tabs. Uses the existing `tabs_controller.js` Stimulus controller for tab state management and keyboard navigation. Implements proper ARIA roles for accessibility.

- **Main elements:**
  - Container `<div>` with `data-controller="tabs"` and Material Design card styling
  - `<ul>` with `role="tablist"` and `aria-label="Profile sections"`
  - Two `<li>` elements, each containing:
    - Account Tab Button: `<button>` with `role="tab"`, `id="account-tab"`, `aria-selected`, `aria-controls`, Stimulus actions, and tab styling
    - Preferences Tab Button: `<button>` with `role="tab"`, `id="preferences-tab"`, `aria-selected`, `aria-controls`, Stimulus actions, and tab styling
  - Tab panels container with two `<div>` elements:
    - Account Tab Panel: `role="tabpanel"`, `id="account-tabpanel"`, `aria-labelledby="account-tab"`, contains AccountSettings partial
    - Preferences Tab Panel: `role="tabpanel"`, `id="preferences-tabpanel"`, `aria-labelledby="preferences-tab"`, contains PreferencesForm partial

- **Handled interactions:**
  - Click on tab button: Calls `tabs#switchTab` action, updates active tab, updates `aria-selected` attributes, shows/hides corresponding tab panels, updates URL query parameter
  - Keyboard navigation (Arrow keys to switch tabs, Home/End to jump to first/last tab, Enter/Space to activate): Handled by `tabs_controller.js` via `handleKeyboardNavigation` method

- **Handled validation:** None (UI navigation component)

- **Types:** None (pure UI component)

- **Props:**
  - `active_tab` (String, optional, default: 'preferences'): String indicating which tab should be active initially ('account' or 'preferences')
  - `user_preferences` (UserPreference | nil, optional): User preferences model instance or nil if preferences don't exist (for passing to PreferencesForm)

### AccountSettings Partial (_account_settings.html.erb)

- **Component description:** Displays account management content in the Account tab. Provides links and information for managing email and password settings via Devise. This is a simple informational component with links to Devise's account management routes.

- **Main elements:**
  - Container `<div>` with tab panel styling and spacing
  - Section header: `<h2>` with "Account Settings" title
  - Description paragraph explaining account management options
  - Link to edit email/password: `<%= link_to 'Edit Email & Password', edit_user_registration_path, class: '...' %>` with Material Design button styling
  - Optional: Additional account information display (email, account creation date, etc.)

- **Handled interactions:**
  - Click on "Edit Email & Password" link: Navigates to Devise's `edit_user_registration_path` (standard Devise route)

- **Handled validation:** None (navigation component)

- **Types:** None (static content with links)

- **Props:** None (uses Devise routes directly)

### PreferencesForm Partial (_preferences_form.html.erb)

- **Component description:** Form component for creating or updating user travel preferences. Handles both the initial load (with or without existing preferences) and form submission. Uses Rails form helpers with Turbo integration. Supports partial updates (all fields optional). Displays validation errors inline below each field.

- **Main elements:**
  - Form wrapper: `<%= form_with model: @user_preferences, url: preferences_path, method: :put, html: { class: 'space-y-6', data: { turbo: true } } do |form| %>`
  - Section header: `<h2>` with "Travel Preferences" title
  - Description paragraph explaining preferences purpose
  - Budget FieldGroup: `render 'shared/form_field', form: form, field_name: :budget, field_type: 'select', select_options: budget_options, required: false`
  - Accommodation FieldGroup: `render 'shared/form_field', form: form, field_name: :accommodation, field_type: 'select', select_options: accommodation_options, required: false`
  - Activities FieldGroup: Custom multi-select checkbox group (see ActivitiesFieldGroup below)
  - Eating Habits FieldGroup: `render 'shared/form_field', form: form, field_name: :eating_habits, field_type: 'select', select_options: eating_habits_options, required: false`
  - Form Actions: `render 'shared/form_actions', submit_text: 'Save Preferences', cancel_path: root_path, cancel_text: 'Cancel'`

- **Handled interactions:**
  - Form field changes: Standard HTML form input events (no custom handlers needed)
  - Form submission: Intercepted by Turbo, submits via AJAX to `PUT /preferences`
  - Checkbox changes (activities): Updates form state, triggers visual feedback

- **Handled validation:**
  - Client-side HTML5 validation: None (all fields optional)
  - Server-side validation errors: Displayed inline below each field via ErrorMessage component when server returns 422 Unprocessable Content
  - Field-specific validation:
    - `budget`: Must be one of: 'budget_conscious', 'standard', 'luxury' (if provided)
    - `accommodation`: Must be one of: 'hotel', 'airbnb', 'hostel', 'resort', 'camping' (if provided)
    - `activities`: Each selected activity must be one of: 'outdoors', 'sightseeing', 'cultural', 'relaxation', 'adventure', 'nightlife', 'shopping' (if provided)
    - `eating_habits`: Must be one of: 'restaurants_only', 'self_prepared', 'mix' (if provided)

- **Types:**
  - `UserPreference` model (or nil for new preferences): ActiveRecord model instance from controller
  - `ErrorResponseDTO` (on validation failure): Contains `errors` hash with field names as keys and arrays of error messages as values

- **Props:**
  - `@user_preferences` (UserPreference | nil): Model instance with existing preferences or nil if preferences don't exist (for new preferences creation)

### ActivitiesFieldGroup Partial (_activities_field_group.html.erb)

- **Component description:** Custom form field group for activities selection. Displays all available activity options as checkboxes. Handles conversion between comma-separated string format (used by API/model) and array format (used by checkboxes). Manages the display of selected activities and handles form submission.

- **Main elements:**
  - Container `<div>` with form field styling
  - Label: `<label>` with "Activities" text and optional indicator (not required)
  - Description text: `<p>` explaining that multiple activities can be selected
  - Checkbox group container: `<div>` with grid or flex layout for checkboxes
  - Activity checkboxes: For each activity option, render a checkbox:
    - `<%= check_box_tag 'preferences[activities][]', activity_value, is_selected, id: "activity_#{activity_value}", class: '...' %>`
    - `<%= label_tag "activity_#{activity_value}", activity_label, class: '...' %>`
  - Hidden field to ensure empty array is sent if no checkboxes are checked: `<%= hidden_field_tag 'preferences[activities][]', '' %>`
  - Error message container: `<%= render 'shared/error_message', errors: errors, field_id: 'activities_errors' %>` (conditionally rendered)

- **Handled interactions:**
  - Checkbox click: Updates form state, visual feedback (checked/unchecked state)
  - Form submission: Activities are submitted as array `preferences[activities][]`, converted to comma-separated string by controller

- **Handled validation:**
  - Server-side validation: Each activity value must be valid (checked by model validation)
  - Error display: If validation fails, error message displayed below checkbox group

- **Types:**
  - `activities` (String | nil): Comma-separated string of activity values (e.g., "cultural,sightseeing") or nil
  - `errors` (Array[String] | nil): Array of error messages for activities field (from model errors)

- **Props:**
  - `form` (ActionView::Helpers::FormBuilder): Rails form builder instance
  - `activities` (String | nil): Current activities value (comma-separated string) from model
  - `errors` (Array[String] | []): Validation errors for activities field

## 5. Types

### DTO Types (API Response Types)

#### UserPreferencesDTO

**Source:** `app/types/dtos/user_preferences_dto.rb`

**Purpose:** Represents user travel preferences as returned by the API in GET /preferences and PUT/PATCH /preferences responses.

**Fields:**
- `id: Integer` - Database ID of the preferences record
- `user_id: Integer` - ID of the user who owns these preferences
- `budget: String | nil` - Budget preference value, one of: 'budget_conscious', 'standard', 'luxury', or nil if not set
- `accommodation: String | nil` - Accommodation preference value, one of: 'hotel', 'airbnb', 'hostel', 'resort', 'camping', or nil if not set
- `activities: String | nil` - Comma-separated string of activity values (e.g., "cultural,sightseeing"), or nil if not set
- `eating_habits: String | nil` - Eating habits preference value, one of: 'restaurants_only', 'self_prepared', 'mix', or nil if not set
- `created_at: String` - ISO 8601 datetime string of when preferences were created
- `updated_at: String` - ISO 8601 datetime string of when preferences were last updated

**Usage:** Used by the controller to serialize preferences data in JSON responses. In HTML views, the ActiveRecord model (`UserPreference`) is used directly instead of the DTO.

#### ErrorResponseDTO

**Source:** `app/types/dtos/error_response_dto.rb`

**Purpose:** Represents error responses from the API, used for validation errors and other error scenarios.

**Fields:**
- `error: String | nil` - Single error message (for 404 Not Found responses)
- `errors: Hash[String, Array[String]] | nil` - Hash of field names to arrays of error messages (for 422 Unprocessable Content responses)

**Usage:** Used when API returns error responses. In HTML views, model errors (`@user_preferences.errors`) are accessed directly.

### Model Types (ActiveRecord)

#### UserPreference

**Source:** `app/models/user_preference.rb`

**Purpose:** ActiveRecord model representing user travel preferences in the database.

**Fields:**
- `id: Integer` - Primary key
- `user_id: Integer` - Foreign key to users table
- `budget: String | nil` - Budget preference value
- `accommodation: String | nil` - Accommodation preference value
- `activities: String | nil` - Comma-separated string of activity values
- `eating_habits: String | nil` - Eating habits preference value
- `created_at: DateTime` - Timestamp of creation
- `updated_at: DateTime` - Timestamp of last update

**Associations:**
- `belongs_to :user`

**Validations:**
- `user_id` uniqueness
- `budget` inclusion in valid enum values (if present)
- `accommodation` inclusion in valid enum values (if present)
- `eating_habits` inclusion in valid enum values (if present)
- `activities` custom validation: each activity in comma-separated string must be a valid enum value

**Usage:** Used directly in views via `@user_preferences` instance variable. Can be nil if preferences don't exist yet.

### Enum Types

#### Budget Enum

**Source:** `app/types/enums/budget.rb`

**Values:**
- `BudgetConscious = 'budget_conscious'`
- `Standard = 'standard'`
- `Luxury = 'luxury'`

**Usage:** Used to generate select options for budget field.

#### Accommodation Enum

**Source:** `app/types/enums/accommodation.rb`

**Values:**
- `Hotel = 'hotel'`
- `Airbnb = 'airbnb'`
- `Hostel = 'hostel'`
- `Resort = 'resort'`
- `Camping = 'camping'`

**Usage:** Used to generate select options for accommodation field.

#### Activity Enum

**Source:** `app/types/enums/activity.rb`

**Values:**
- `Outdoors = 'outdoors'`
- `Sightseeing = 'sightseeing'`
- `Cultural = 'cultural'`
- `Relaxation = 'relaxation'`
- `Adventure = 'adventure'`
- `Nightlife = 'nightlife'`
- `Shopping = 'shopping'`

**Usage:** Used to generate checkbox options for activities field.

#### EatingHabit Enum

**Source:** `app/types/enums/eating_habit.rb`

**Values:**
- `RestaurantsOnly = 'restaurants_only'`
- `SelfPrepared = 'self_prepared'`
- `Mix = 'mix'`

**Usage:** Used to generate select options for eating_habits field.

### ViewModel Types (Component-Specific)

**No custom ViewModel types are required for this view.** The view uses ActiveRecord model instances (`UserPreference`) directly from the controller. Component state (active tab) is managed via the existing Stimulus `tabs_controller.js`, not through ViewModels.

### Form Helper Types

**Helper Methods (to be added to `PreferencesHelper` or `ApplicationHelper`):**

#### budget_options
- **Returns:** `Array<[String, String]>` - Array of `[label, value]` pairs for budget select dropdown
- **Example:** `[['Budget Conscious', 'budget_conscious'], ['Standard', 'standard'], ['Luxury', 'luxury']]`

#### accommodation_options
- **Returns:** `Array<[String, String]>` - Array of `[label, value]` pairs for accommodation select dropdown
- **Example:** `[['Hotel', 'hotel'], ['Airbnb', 'airbnb'], ['Hostel', 'hostel'], ['Resort', 'resort'], ['Camping', 'camping']]`

#### activity_options
- **Returns:** `Array<[String, String]>` - Array of `[label, value]` pairs for activity checkboxes
- **Example:** `[['Outdoors', 'outdoors'], ['Sightseeing', 'sightseeing'], ['Cultural', 'cultural'], ...]`

#### eating_habits_options
- **Returns:** `Array<[String, String]>` - Array of `[label, value]` pairs for eating habits select dropdown
- **Example:** `[['Restaurants Only', 'restaurants_only'], ['Self-Prepared', 'self_prepared'], ['Mix', 'mix']]`

## 6. State Management

**Server-Side State:**
- User preferences are stored in the database and loaded via `PreferencesController#show` or `ProfilesController#show`
- For Profile view: Controller loads preferences or sets `@user_preferences = nil` if preferences don't exist
- Active tab state can be determined from URL query parameter (`?tab=account` or `?tab=preferences`)

**Client-Side State (Stimulus Controller):**

The existing `tabs_controller.js` Stimulus controller manages tab navigation state:

**Controller Name:** `tabs_controller.js` (already exists)

**Purpose:** Manage active tab state, handle tab switching, maintain proper ARIA attributes for accessibility, and sync URL query parameters.

**State Variables:**
- `activeTab: String` - Current active tab identifier ('account' or 'preferences')
- `tabButtons: NodeList` - Reference to tab button elements (via `tabTargets`)
- `tabPanels: NodeList` - Reference to tab panel elements (via `panelTargets`)

**Actions:**
- `switchTab(event)` - Switches active tab, updates ARIA attributes, shows/hides panels, updates URL query parameter
- `handleKeyboardNavigation(event)` - Handles arrow key navigation between tabs (ArrowLeft, ArrowRight, Home, End)

**Lifecycle:**
- `connect()` - Initialize active tab from URL query parameter or hash, set up ARIA attributes, attach keyboard listeners
- `disconnect()` - Clean up event listeners

**Custom Hook:** Not required. Standard Stimulus controller pattern is sufficient. The existing `tabs_controller.js` is reused.

**Form State:**
- Form state is managed by Rails form helpers and Turbo
- On form submission, Turbo intercepts the request and handles the response
- On validation errors (422), form is re-rendered with error messages, preserving user input
- On success (200), form is updated with new preference values, and flash message is displayed

**Activities Checkbox State:**
- Checkbox state is managed by standard HTML form behavior
- Selected activities are stored as an array in the form: `preferences[activities][]`
- On form submission, the controller converts the array to a comma-separated string
- On form load, the comma-separated string (if present) is converted to an array to determine which checkboxes should be checked

## 7. API Integration

### GET /preferences

**Endpoint:** `GET /preferences`

**Purpose:** Retrieve current user's travel preferences when loading the Preferences form.

**Request:**
- **Method:** `GET`
- **Path:** `/preferences`
- **Headers:**
  - `Accept: text/html` (for HTML view rendering)
  - `X-CSRF-Token: <authenticity_token>` (Rails CSRF protection, automatically included)
- **Authentication:** Required (Devise session authentication)

**Success Response (200 OK):**
- **Status:** `200 OK`
- **Content-Type:** `text/html`
- **Body:** HTML view with preferences form pre-populated with existing values
- **Controller Action:** `PreferencesController#show` renders `show.html.erb` with `@user_preferences` set to the user's preferences record

**Error Response (404 Not Found):**
- **Status:** `404 Not Found`
- **Content-Type:** `text/html`
- **Body:** HTML view with empty form (no preferences exist yet)
- **Controller Action:** `PreferencesController#show` returns 404, but for HTML requests, redirects to root with flash message. For Profile view, controller should handle this gracefully by setting `@user_preferences = nil` and rendering empty form.

**Implementation Note:** For the Profile view, the controller should load preferences and handle the nil case gracefully. The form should support both creating new preferences (`@user_preferences = nil`) and updating existing preferences (`@user_preferences` is a UserPreference instance).

### PUT /preferences (Upsert Operation)

**Endpoint:** `PUT /preferences`

**Purpose:** Create or update user's travel preferences. This is an upsert operation - if preferences don't exist, they are created; if they exist, they are updated.

**Request:**
- **Method:** `PUT` (or `PATCH`)
- **Path:** `/preferences`
- **Headers:**
  - `Content-Type: application/x-www-form-urlencoded` (HTML form submission)
  - `X-CSRF-Token: <authenticity_token>` (Rails CSRF protection, automatically included by `form_with`)
  - `Accept: text/html` or `text/vnd.turbo-stream.html` (for Turbo Stream responses)
- **Authentication:** Required (Devise session authentication)
- **Body (form data):**
  ```
  preferences[budget]=standard
  preferences[accommodation]=hotel
  preferences[activities][]=cultural
  preferences[activities][]=sightseeing
  preferences[eating_habits]=mix
  ```
  Note: Activities are submitted as an array `preferences[activities][]`, which the controller converts to a comma-separated string.

**Success Response (200 OK):**
- **Status:** `200 OK`
- **Content-Type:** `text/html`
- **Body:** Redirect to `preferences_path` with flash message `flash[:notice] = 'Preferences updated successfully'`
- **Turbo:** Handles redirect automatically
- **Controller Action:** `PreferencesController#update` saves preferences and redirects with success message

**Error Response (422 Unprocessable Content):**
- **Status:** `422 Unprocessable Content`
- **Content-Type:** `text/html` or `text/vnd.turbo-stream.html` (Turbo Stream)
- **Body:** HTML form re-rendered with validation errors displayed inline
- **Error Format:** Model errors available via `@user_preferences.errors`
- **Controller Action:** `PreferencesController#update` renders form with errors, preserving user input
- **Turbo:** Updates form DOM with error messages without full page reload

**Implementation Note:** The form uses `form_with` which automatically handles Turbo submission. On success, the user is redirected and sees a success message. On validation errors, the form is re-rendered with inline error messages.

## 8. User Interactions

### 8.1. Viewing Profile & Preferences

1. **Navigate to Profile Page:**
   - User clicks "Profile & Preferences" link in sidebar navigation
   - Action: `GET /profile`
   - Result: Profile page loads with Preferences tab active by default (or Account tab if `?tab=account` is in URL)
   - Initial State: If preferences exist, form is pre-populated; if not, form is empty

2. **Switch Between Tabs:**
   - User clicks "Account" or "Preferences" tab button
   - Action: `tabs#switchTab` Stimulus action triggered
   - Result: Active tab switches, corresponding panel is shown, other panel is hidden, URL query parameter updates (`?tab=account` or `?tab=preferences`)
   - Keyboard Navigation: User can use Arrow keys to navigate between tabs, Home/End to jump to first/last tab

3. **View Account Tab:**
   - User clicks "Account" tab
   - Result: Account tab panel is displayed, showing account management information and link to Devise's edit user registration page

### 8.2. Setting Travel Preferences (First Time)

1. **Navigate to Preferences Tab:**
   - User clicks "Preferences" tab (or tab is active by default)
   - Result: Preferences form is displayed with empty fields (no preferences exist yet)

2. **Fill in Preferences:**
   - User selects values from dropdown menus (budget, accommodation, eating habits)
   - User checks one or more activity checkboxes
   - Action: Form input events (standard HTML form behavior)
   - Result: Form values update in real-time

3. **Submit Form:**
   - User clicks "Save Preferences" button
   - Action: Form submission via Turbo (`PUT /preferences`)
   - Validation: Client-side HTML5 validation runs first (all fields optional, so no required field validation)
   - Success Result (200): Preferences are created in database, user is redirected to preferences page with success flash message "Preferences updated successfully"
   - Error Result (422): Form re-renders with inline error messages via Turbo Stream, user input preserved

### 8.3. Updating Existing Preferences

1. **Navigate to Preferences Tab:**
   - User clicks "Preferences" tab
   - Result: Preferences form is displayed with existing preference values pre-populated

2. **Modify Preferences:**
   - User changes one or more field values (all fields optional for partial updates)
   - User can uncheck activity checkboxes or check new ones
   - Action: Form input events
   - Result: Form values update in real-time

3. **Submit Form:**
   - User clicks "Save Preferences" button
   - Action: Form submission via Turbo (`PUT /preferences`)
   - Validation: Client-side and server-side validation
   - Success Result (200): Preferences are updated in database, user is redirected with success flash message
   - Error Result (422): Form re-renders with inline error messages, user input preserved

4. **Cancel:**
   - User clicks "Cancel" link
   - Action: Navigation to root path (`/`)
   - Result: Changes are discarded, user returns to trips list

### 8.4. Activity Checkbox Interactions

1. **Select Activity:**
   - User clicks an activity checkbox
   - Action: Checkbox `change` event
   - Result: Checkbox becomes checked, visual feedback (checked state)

2. **Deselect Activity:**
   - User clicks a checked activity checkbox
   - Action: Checkbox `change` event
   - Result: Checkbox becomes unchecked, visual feedback (unchecked state)

3. **Multiple Selection:**
   - User can select multiple activities by clicking multiple checkboxes
   - Result: All selected activities are included in form submission as array `preferences[activities][]`

## 9. Conditions and Validation

### 9.1. Field Validation Rules

**Budget Field:**
- **Condition:** If provided, must be one of: 'budget_conscious', 'standard', 'luxury'
- **Verified by:** Model validation `validates :budget, inclusion: { in: Enums::Budget.string_values, allow_nil: true }`
- **Component:** Budget select dropdown (FormFieldGroup)
- **Client-side:** Dropdown only allows valid values (no client-side validation needed)
- **Server-side:** Model validates inclusion in enum values
- **Effect:** If validation fails, error message "is not included in the list" displayed below budget field

**Accommodation Field:**
- **Condition:** If provided, must be one of: 'hotel', 'airbnb', 'hostel', 'resort', 'camping'
- **Verified by:** Model validation `validates :accommodation, inclusion: { in: Enums::Accommodation.string_values, allow_nil: true }`
- **Component:** Accommodation select dropdown (FormFieldGroup)
- **Client-side:** Dropdown only allows valid values (no client-side validation needed)
- **Server-side:** Model validates inclusion in enum values
- **Effect:** If validation fails, error message "is not included in the list" displayed below accommodation field

**Activities Field:**
- **Condition:** If provided, each activity in the comma-separated string must be one of: 'outdoors', 'sightseeing', 'cultural', 'relaxation', 'adventure', 'nightlife', 'shopping'
- **Verified by:** Model custom validation method `activities_valid` that splits the comma-separated string and validates each value
- **Component:** Activities checkbox group (ActivitiesFieldGroup)
- **Client-side:** Checkboxes only allow valid values (no client-side validation needed)
- **Server-side:** Custom validation method checks each activity value against enum values
- **Effect:** If validation fails, error message "contains invalid values: [invalid_values]" displayed below activities field group

**Eating Habits Field:**
- **Condition:** If provided, must be one of: 'restaurants_only', 'self_prepared', 'mix'
- **Verified by:** Model validation `validates :eating_habits, inclusion: { in: Enums::EatingHabit.string_values, allow_nil: true }`
- **Component:** Eating habits select dropdown (FormFieldGroup)
- **Client-side:** Dropdown only allows valid values (no client-side validation needed)
- **Server-side:** Model validates inclusion in enum values
- **Effect:** If validation fails, error message "is not included in the list" displayed below eating_habits field

### 9.2. Optional Fields

**Condition:** All preference fields are optional (partial updates allowed)
- **Verified by:** Model validations use `allow_nil: true` for all fields
- **Component:** All form fields (no `required` attribute on inputs)
- **Client-side:** No HTML5 `required` attributes on form fields
- **Server-side:** All fields can be nil or empty
- **Effect:** User can submit form with any combination of fields filled or empty

### 9.3. Preferences Existence

**Condition:** Preferences may or may not exist for a user
- **Verified by:** Controller checks `current_user.user_preference` (can be nil)
- **Component:** PreferencesForm partial (handles both cases)
- **Client-side:** Form works with both `@user_preferences = nil` and `@user_preferences = UserPreference instance`
- **Server-side:** Controller uses upsert pattern: `current_user.user_preference || current_user.build_user_preference`
- **Effect:** Form displays empty fields if preferences don't exist, pre-populated fields if they do

### 9.4. Authentication and Authorization

**Condition:** User must be authenticated to access preferences
- **Verified by:** `before_action :authenticate_user!` in PreferencesController
- **Component:** Entire view (handled at controller level)
- **Effect:** Unauthenticated users redirected to login page

**Condition:** User can only view/edit their own preferences
- **Verified by:** `current_user.user_preference` scopes preferences to current user
- **Component:** Preferences form (handled at controller level)
- **Effect:** User can only access their own preferences (automatically enforced by `current_user`)

## 10. Error Handling

### 10.1. Validation Errors (422 Unprocessable Content)

**Scenario:** Server returns validation errors after form submission.

**Handling:**
1. Controller renders form with `@user_preferences` model containing errors (via `user_preferences.errors`)
2. Turbo Stream response (or standard HTML response) updates form HTML with error messages
3. ErrorMessage components are rendered for each field with errors
4. User input is preserved (form values remain in inputs, checkbox states maintained)
5. Inline error messages appear below each invalid field
6. Form remains on same page (no redirect), allowing user to correct errors and resubmit

**Implementation:**
- Controller action (update) responds with `status: :unprocessable_content` when validation fails
- View renders form partial with errors displayed via `form.object.errors[field_name]`
- FormFieldGroup components automatically display errors if present
- Turbo handles the update automatically (no custom JavaScript required)

**Error Message Format:**
- Field-specific errors: `errors[:budget] = ["is not included in the list"]`
- Activities errors: `errors[:activities] = ["contains invalid values: invalid_activity"]`

### 10.2. Preferences Not Found (404)

**Scenario:** User attempts to view preferences that don't exist (GET /preferences returns 404).

**Handling for Profile View:**
1. Controller checks if preferences exist: `@user_preferences = current_user.user_preference`
2. If nil, controller sets `@user_preferences = nil` (does not return 404 for HTML requests in Profile view)
3. Form is rendered with empty fields (new preferences creation mode)
4. User can fill in form and submit to create preferences

**Handling for Direct Preferences Access:**
- If user directly accesses `GET /preferences` (not via Profile view), controller returns 404 with error message
- For HTML format, redirects to root with flash alert: "Preferences not found. Please create your preferences."
- For JSON format, returns 404 JSON response with error message

### 10.3. Network Errors

**Scenario:** Network failure or server error during form submission.

**Handling:**
1. Turbo handles network errors automatically
2. Browser may display default error message or Turbo may show error state
3. User can retry form submission
4. Form values are preserved (Turbo maintains form state)

**Implementation:**
- No custom error handling required - Turbo and browser handle network errors
- Optionally, a Stimulus controller could be added to show custom error messages or disable form during submission

### 10.4. Authentication Errors (401)

**Scenario:** User session expires or user is not authenticated.

**Handling:**
1. Devise `before_action :authenticate_user!` intercepts request
2. User is redirected to login page
3. After login, user is redirected back to the page they were trying to access (if configured)
4. Flash message may indicate authentication is required

**Implementation:**
- Handled automatically by Devise
- No custom error handling required in view

### 10.5. Server Errors (500)

**Scenario:** Unexpected server error (database failure, etc.).

**Handling:**
1. Rails error handling catches exception
2. Error is logged to error tracking service
3. 500 error page is rendered (standard Rails error page or custom error page)
4. User sees error page and can report issue or retry

**Implementation:**
- Handled by Rails error handling middleware
- No custom error handling required in view

## 11. Implementation Steps

1. **Create Profile Route:**
   - Add route to `config/routes.rb`: `get 'profile', to: 'profiles#show', as: :profile`
   - Or create a ProfilesController if it doesn't exist

2. **Create ProfilesController:**
   - Create `app/controllers/profiles_controller.rb`
   - Add `show` action that loads user preferences: `@user_preferences = current_user.user_preference`
   - Set active tab from URL parameter: `@active_tab = params[:tab] || 'preferences'`
   - Add `before_action :authenticate_user!`
   - Render `app/views/profiles/show.html.erb`

3. **Create Profile View:**
   - Create `app/views/profiles/show.html.erb`
   - Add page header: `render 'shared/page_header', title: 'Profile & Preferences'`
   - Add tab navigation: `render 'profiles/tab_navigation', active_tab: @active_tab, user_preferences: @user_preferences`

4. **Create Tab Navigation Partial:**
   - Create `app/views/profiles/_tab_navigation.html.erb`
   - Implement tab list with Account and Preferences tabs
   - Add tab panels container
   - Include Account tab panel with AccountSettings partial
   - Include Preferences tab panel with PreferencesForm partial
   - Add `data-controller="tabs"` and tab button/panel structure matching existing tab implementation pattern

5. **Create Account Settings Partial:**
   - Create `app/views/profiles/_account_settings.html.erb`
   - Add section header "Account Settings"
   - Add description text
   - Add link to `edit_user_registration_path` with Material Design button styling

6. **Create Preferences Form Partial:**
   - Create `app/views/profiles/_preferences_form.html.erb`
   - Add form with `form_with model: @user_preferences, url: preferences_path, method: :put`
   - Add section header "Travel Preferences"
   - Add description text
   - Add Budget field using `render 'shared/form_field'` with select type
   - Add Accommodation field using `render 'shared/form_field'` with select type
   - Add Activities field using custom ActivitiesFieldGroup partial
   - Add Eating Habits field using `render 'shared/form_field'` with select type
   - Add form actions: `render 'shared/form_actions', submit_text: 'Save Preferences', cancel_path: root_path`

7. **Create Activities Field Group Partial:**
   - Create `app/views/profiles/_activities_field_group.html.erb`
   - Add label "Activities"
   - Generate checkbox options from Activity enum
   - Handle comma-separated string to array conversion for checked state
   - Render checkboxes with proper names: `preferences[activities][]`
   - Add hidden field to ensure empty array submission
   - Add error message display using `render 'shared/error_message'`

8. **Create Helper Methods:**
   - Add to `app/helpers/preferences_helper.rb` or `app/helpers/application_helper.rb`:
     - `budget_options` - Returns array of `[label, value]` pairs for budget select
     - `accommodation_options` - Returns array of `[label, value]` pairs for accommodation select
     - `activity_options` - Returns array of `[label, value]` pairs for activity checkboxes
     - `eating_habits_options` - Returns array of `[label, value]` pairs for eating habits select

9. **Update PreferencesController (if needed):**
   - Ensure `update` action handles HTML format correctly (already implemented)
   - Ensure `show` action can handle HTML format for direct access (already implemented)
   - Verify flash messages are set correctly

10. **Update Controller to Handle Activities Array:**
    - Verify `PreferencesUpdateCommand` handles activities array conversion (check if it needs updates)
    - Activities are submitted as `preferences[activities][]` (array), but stored as comma-separated string
    - Controller should convert array to comma-separated string before saving

11. **Test Form Submission:**
    - Test creating new preferences (when none exist)
    - Test updating existing preferences
    - Test partial updates (only some fields)
    - Test validation errors (invalid enum values)
    - Test activities checkbox selection and deselection

12. **Test Tab Navigation:**
    - Test switching between Account and Preferences tabs
    - Test keyboard navigation (Arrow keys, Home, End)
    - Test URL parameter persistence (`?tab=account`, `?tab=preferences`)
    - Test initial tab state based on URL

13. **Test Error Handling:**
    - Test validation errors display correctly
    - Test form preserves user input on validation errors
    - Test 404 handling if preferences don't exist (for Profile view, should show empty form)
    - Test authentication requirement

14. **Add Accessibility Features:**
    - Verify ARIA roles are correct on tabs (tablist, tab, tabpanel)
    - Verify keyboard navigation works
    - Verify form labels are associated with inputs
    - Verify error messages are associated with fields via `aria-describedby`

15. **Style and Polish:**
    - Apply Material Design styling to all components
    - Ensure responsive design works on mobile devices
    - Verify spacing and layout match design system
    - Test with different screen sizes

