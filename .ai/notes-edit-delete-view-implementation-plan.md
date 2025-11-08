# View Implementation Plan: Notes Edit and Delete

## 1. Overview

This implementation plan describes how to enhance the existing notes component to support editing and deleting notes. The notes are currently displayed as read-only items in the trip detail view. This update will add edit and delete functionality with inline editing capabilities, delete confirmation, and seamless updates using Turbo Stream responses.

The implementation follows the existing Rails + Hotwire (Turbo/Stimulus) architecture and maintains consistency with the current UI patterns using Tailwind CSS and Material Design components.

## 2. View Routing

The notes edit and delete functionality is accessible within the existing trip detail view:
- **Path:** `/trips/:id` (with `tab=notes` parameter or default active tab)
- **Route:** `GET /trips/:id` → `trips#show`
- **Notes Tab Panel:** Rendered via `_notes_tab.html.erb` partial
- **Note Item:** Rendered via `_note_item.html.erb` partial (to be enhanced)

The edit and delete actions use nested routes:
- **Update:** `PUT/PATCH /trips/:trip_id/notes/:id` → `trips/notes#update`
- **Delete:** `DELETE /trips/:trip_id/notes/:id` → `trips/notes#destroy`

## 3. Component Structure

```
Notes Tab Panel
├── Notes List Component (_notes_list.html.erb)
│   └── Note Item Component (_note_item.html.erb) [TO BE ENHANCED]
│       ├── Note Display Mode (default)
│       │   ├── Note Content (read-only)
│       │   ├── Timestamp
│       │   └── Action Buttons (Edit, Delete)
│       └── Note Edit Mode
│           ├── Edit Form
│           │   ├── Textarea Field
│           │   └── Form Actions (Save, Cancel)
│           └── Validation Errors (if any)
└── Add Note Form Component (_add_note_form.html.erb) [unchanged]
```

## 4. Component Details

### Note Item Component (_note_item.html.erb)

**Component Description:**
The note item component displays a single note with two modes: display mode (default) and edit mode. In display mode, it shows the note content, timestamps, and action buttons. In edit mode, it shows an inline form for editing the note content. The component uses a Stimulus controller to manage the edit mode state and form submission.

**Main Elements:**
- **Container:** `<div id="note_<%= note.id %>">` - Wrapper with unique ID for Turbo Stream targeting
- **Display Mode Section:**
  - Note content paragraph with formatted text
  - Timestamp section with created/updated dates
  - Action buttons container with Edit and Delete buttons
- **Edit Mode Section (initially hidden):**
  - Edit form with textarea field
  - Form action buttons (Save, Cancel)
  - Error message container (for validation errors)

**Handled Interactions:**
1. **Edit Button Click:**
   - Event: `click` on edit button
   - Action: Toggle to edit mode via Stimulus controller
   - Result: Hide display mode, show edit form with current content pre-filled

2. **Cancel Button Click:**
   - Event: `click` on cancel button
   - Action: Toggle back to display mode via Stimulus controller
   - Result: Hide edit form, show display mode, discard unsaved changes

3. **Save Button Click / Form Submit:**
   - Event: `submit` on edit form
   - Action: Submit form via Turbo to `PUT/PATCH /trips/:trip_id/notes/:id`
   - Result: Server responds with Turbo Stream that updates the note item or shows errors

4. **Delete Button Click:**
   - Event: `click` on delete button
   - Action: Show confirmation dialog, then submit DELETE request via Turbo
   - Result: Server responds with Turbo Stream that removes the note from DOM

5. **Form Validation:**
   - Event: `input` and `blur` on textarea
   - Action: Client-side validation (optional, via Stimulus)
   - Result: Real-time feedback on content length (max 10,000 characters)

**Handled Validation:**
- **Content Presence:** Required field (enforced by HTML5 `required` attribute and server-side)
- **Content Length:** Maximum 10,000 characters (enforced by HTML5 `maxlength` attribute and server-side)
- **Empty Content:** Server returns 422 if content is blank after trimming
- **Server Validation Errors:** Displayed inline below the textarea field via Turbo Stream response

**Types:**
- **Input:** `Note` model instance (ActiveRecord object)
- **DTO (API Response):** `DTOs::NoteDTO` with fields:
  - `id: Integer`
  - `trip_id: Integer`
  - `content: String`
  - `created_at: String` (ISO 8601)
  - `updated_at: String` (ISO 8601)
- **Command (API Request):** `Commands::NoteUpdateCommand` with fields:
  - `content: String` (required)

**Props:**
- `note: Note` - The note model instance to display/edit
- `trip: Trip` - The parent trip (for form URL generation)

### Notes List Component (_notes_list.html.erb)

**Component Description:**
The notes list component renders a collection of note items or an empty state. It serves as a container for the note items and is updated via Turbo Stream when notes are added, updated, or deleted.

**Main Elements:**
- **Container:** `<div id="notes_list">` - Wrapper with unique ID for Turbo Stream targeting
- **Notes Items Container:** `<div id="notes_list_items">` - Contains all note item components
- **Empty State:** Displayed when no notes exist

**Handled Interactions:**
- None directly (delegated to child note items)

**Handled Validation:**
- None (validation handled at note item level)

**Types:**
- **Input:** `ActiveRecord::Relation<Note>` or `Array<Note>`

**Props:**
- `notes: ActiveRecord::Relation<Note>` - Collection of notes to display

### Note Edit Form (Inline in _note_item.html.erb)

**Component Description:**
The edit form is embedded within the note item component and appears when edit mode is activated. It provides an inline editing experience without navigating to a separate page.

**Main Elements:**
- **Form:** `<%= form_with model: [trip, note], local: false %>` - Turbo-enabled form
- **Textarea Field:** Content input with validation attributes
- **Form Actions:** Save and Cancel buttons
- **Error Container:** Displays validation errors below the textarea

**Handled Interactions:**
1. **Form Submit:**
   - Event: `submit` on form
   - Action: POST/PATCH request via Turbo to update endpoint
   - Result: Turbo Stream response updates note item or shows errors

2. **Cancel:**
   - Event: `click` on cancel button
   - Action: Prevent form submission, toggle back to display mode
   - Result: Edit form hidden, display mode shown

**Handled Validation:**
- **Client-side:** HTML5 validation (required, maxlength)
- **Server-side:** Content presence and length validation
- **Error Display:** Inline error messages below textarea via Turbo Stream

**Types:**
- **Form Model:** `Note` (ActiveRecord)
- **Request Payload:** `{ note: { content: String } }`
- **Response:** Turbo Stream or JSON with `NoteDTO`

**Props:**
- Inherited from parent note item component

## 5. Types

### Existing Types (No New Types Required)

**NoteDTO (app/types/dtos/note_dto.rb):**
- `id: Integer` - Note ID
- `trip_id: Integer` - Parent trip ID
- `content: String` - Note content text
- `created_at: String` - ISO 8601 datetime string
- `updated_at: String` - ISO 8601 datetime string

**NoteUpdateCommand (app/types/commands/note_update_command.rb):**
- `content: String` - Note content (required, from form params)

**Note Model (app/models/note.rb):**
- ActiveRecord model with:
  - `id: Integer`
  - `trip_id: Integer` (foreign key)
  - `content: String` (required, max 10,000 characters)
  - `created_at: DateTime`
  - `updated_at: DateTime`
  - Validations: `presence: true`, `length: { maximum: 10_000 }`

### ViewModel/State Types (Stimulus Controller)

**NoteEditController State:**
- `isEditing: Boolean` - Tracks whether note is in edit mode
- `originalContent: String` - Stores original content for cancel operation
- `formElement: HTMLElement` - Reference to the edit form element
- `textareaElement: HTMLElement` - Reference to the textarea element

## 6. State Management

### Component State

The note item component uses a Stimulus controller (`note-edit-controller.js`) to manage local UI state:

1. **Edit Mode State:**
   - **Variable:** `isEditing` (Boolean, initially `false`)
   - **Purpose:** Tracks whether the note is currently in edit mode
   - **Updates:** Toggled by Edit and Cancel button clicks
   - **Effect:** Shows/hides display mode and edit form sections

2. **Original Content State:**
   - **Variable:** `originalContent` (String)
   - **Purpose:** Stores the original note content when entering edit mode
   - **Updates:** Set when Edit button is clicked
   - **Effect:** Used to restore content if user cancels editing

3. **Form Submission State:**
   - **Variable:** `isSubmitting` (Boolean, initially `false`)
   - **Purpose:** Tracks form submission in progress
   - **Updates:** Set to `true` on form submit, reset on response
   - **Effect:** Disables form buttons during submission to prevent double-submission

### Server State

Server state is managed via Turbo Stream responses:
- **After Update:** Server responds with Turbo Stream that updates the note item DOM element
- **After Delete:** Server responds with Turbo Stream that removes the note item DOM element
- **On Error:** Server responds with Turbo Stream that re-renders the note item with error messages

### No Global State Required

No application-wide state management (e.g., Redux, Vuex) is needed. All state is local to components and managed via:
- Stimulus controllers for UI state
- Turbo Stream for server-driven DOM updates
- Server-side session state for authentication

## 7. API Integration

### Update Note Endpoint

**Endpoint:** `PUT/PATCH /trips/:trip_id/notes/:id`

**Request:**
- **Method:** `PATCH` (Rails prefers PATCH over PUT)
- **URL:** `/trips/:trip_id/notes/:id`
- **Headers:**
  - `Content-Type: application/x-www-form-urlencoded` (HTML form submission)
  - `X-CSRF-Token: <authenticity_token>` (Rails CSRF protection)
  - `Accept: text/vnd.turbo-stream.html` (for Turbo Stream responses)
- **Body (form data):**
  ```
  note[content]=Updated note content here
  _method=PATCH
  ```
- **Authentication:** Required (Devise session-based)

**Success Response (200 OK):**
- **Status:** `200 OK`
- **Content-Type:** `text/vnd.turbo-stream.html`
- **Body:** Turbo Stream response:
  ```erb
  <%= turbo_stream.update "note_#{@note.id}" do %>
    <%= render 'trips/note_item', note: @note %>
  <% end %>
  <%= turbo_stream.update "toast-container" do %>
    <%= render 'shared/toast_container' %>
  <% end %>
  ```
- **Effect:** Note item is updated in DOM, flash message shown in toast

**Error Response (422 Unprocessable Content):**
- **Status:** `422 Unprocessable Content`
- **Content-Type:** `text/vnd.turbo-stream.html`
- **Body:** Turbo Stream response that re-renders note item with errors:
  ```erb
  <%= turbo_stream.update "notes_list" do %>
    <%= render 'trips/notes_list', notes: @trip.notes %>
  <% end %>
  ```
- **Effect:** Notes list is re-rendered with validation errors displayed

**Error Response (404 Not Found):**
- **Status:** `404 Not Found`
- **Content-Type:** `text/html` or `application/json`
- **Body:** Error message (handled by `ApplicationController#handle_not_found`)
- **Effect:** Redirect to root with flash alert or JSON error response

### Delete Note Endpoint

**Endpoint:** `DELETE /trips/:trip_id/notes/:id`

**Request:**
- **Method:** `DELETE
- **URL:** `/trips/:trip_id/notes/:id`
- **Headers:**
  - `X-CSRF-Token: <authenticity_token>`
  - `Accept: text/vnd.turbo-stream.html`
- **Body:** None (DELETE requests have no body)
- **Authentication:** Required (Devise session-based)

**Success Response (200 OK):**
- **Status:** `200 OK`
- **Content-Type:** `text/vnd.turbo-stream.html`
- **Body:** Turbo Stream response:
  ```erb
  <%= turbo_stream.remove "note_#{@note_id}" %>
  <%= turbo_stream.update "toast-container" do %>
    <%= render 'shared/toast_container' %>
  <% end %>
  ```
- **Effect:** Note item is removed from DOM, flash message shown in toast

**Error Response (404 Not Found):**
- **Status:** `404 Not Found`
- **Content-Type:** `text/html` or `application/json`
- **Body:** Error message (handled by `ApplicationController#handle_not_found`)
- **Effect:** Redirect to root with flash alert or JSON error response

**Error Response (422 Unprocessable Content):**
- **Status:** `422 Unprocessable Content` (if deletion fails)
- **Content-Type:** `text/vnd.turbo-stream.html`
- **Body:** Turbo Stream response that re-renders notes list with error
- **Effect:** Notes list is re-rendered, error message shown

## 8. User Interactions

### 8.1. Editing a Note

1. **Initiate Edit:**
   - **User Action:** Click "Edit" button on a note item
   - **UI Change:** Note item switches to edit mode
   - **Behavior:**
     - Display mode section is hidden
     - Edit form section is shown
     - Textarea is pre-filled with current note content
     - Original content is stored for cancel operation
     - Edit and Delete buttons are hidden
     - Save and Cancel buttons are shown

2. **Modify Content:**
   - **User Action:** Type or edit text in the textarea
   - **UI Change:** Textarea value updates in real-time
   - **Behavior:**
     - Character count can be displayed (optional enhancement)
     - Max length indicator shows remaining characters (optional)
     - No validation errors shown yet (validated on submit)

3. **Save Changes:**
   - **User Action:** Click "Save" button or press Enter (if form allows)
   - **UI Change:** Form submission initiated
   - **Behavior:**
     - Form is submitted via Turbo to update endpoint
     - Save button is disabled during submission (loading state)
     - On success: Note item updates with new content and updated timestamp
     - On error: Validation errors are displayed below textarea
     - Edit mode remains active if errors occur
     - Edit mode closes if save succeeds

4. **Cancel Edit:**
   - **User Action:** Click "Cancel" button
   - **UI Change:** Note item switches back to display mode
   - **Behavior:**
     - Edit form is hidden
     - Display mode is shown
     - Original content is restored (if any changes were made)
     - No server request is made

### 8.2. Deleting a Note

1. **Initiate Delete:**
   - **User Action:** Click "Delete" button on a note item
   - **UI Change:** Confirmation dialog appears
   - **Behavior:**
     - Browser `confirm()` dialog or custom modal shows confirmation message
     - Message: "Are you sure you want to delete this note? This action cannot be undone."
     - User can confirm or cancel

2. **Confirm Delete:**
   - **User Action:** Click "OK" in confirmation dialog
   - **UI Change:** Delete request is sent
   - **Behavior:**
     - DELETE request is sent via Turbo to delete endpoint
     - Delete button is disabled during request (optional)
     - On success: Note item is removed from DOM via Turbo Stream
     - Flash message appears: "Note deleted successfully"
     - Notes list updates (empty state shown if last note deleted)

3. **Cancel Delete:**
   - **User Action:** Click "Cancel" in confirmation dialog
   - **UI Change:** Dialog closes, no action taken
   - **Behavior:**
     - No server request is made
     - Note remains unchanged

### 8.3. Error Handling Interactions

1. **Validation Error on Update:**
   - **User Action:** Submit form with invalid content (empty or too long)
   - **UI Change:** Error messages appear below textarea
   - **Behavior:**
     - Server responds with 422 status
     - Turbo Stream re-renders note item with errors
     - Edit mode remains active
     - User can correct errors and resubmit

2. **Network Error:**
   - **User Action:** Submit form when network is unavailable
   - **UI Change:** Error message appears
   - **Behavior:**
     - Turbo handles network errors
     - Error toast or inline message is shown
     - User can retry the operation

3. **Not Found Error (404):**
   - **User Action:** Attempt to edit/delete a note that no longer exists
   - **UI Change:** Error message appears
   - **Behavior:**
     - Server responds with 404 status
     - `ApplicationController#handle_not_found` handles the error
     - User is redirected or shown error message
     - Notes list may be refreshed

## 9. Conditions and Validation

### 9.1. Client-Side Validation

**Content Field Validation:**
- **Required:** Content must not be empty (HTML5 `required` attribute)
- **Max Length:** Content must not exceed 10,000 characters (HTML5 `maxlength` attribute)
- **Whitespace:** Leading/trailing whitespace is trimmed on server (client can show warning)
- **Validation Trigger:** On form submit (HTML5 validation)
- **Error Display:** Browser default validation messages or custom inline errors

**Form Submission Conditions:**
- Form can only be submitted if:
  - Content is not empty (after trimming)
  - Content length is within limit (0 < length <= 10,000)
  - User is authenticated (enforced by server)
  - Note belongs to user's trip (enforced by server)

### 9.2. Server-Side Validation

**Content Validation (Note Model):**
- **Presence:** `validates :content, presence: true`
  - Error message: "can't be blank"
  - Applied: Before save
- **Length:** `validates :content, length: { maximum: 10_000 }`
  - Error message: "is too long (maximum is 10000 characters)"
  - Applied: Before save

**Authorization Validation:**
- **Trip Ownership:** Note must belong to a trip owned by the authenticated user
  - Enforced by: `current_user.trips.find(params[:trip_id])` in `set_trip` before_action
  - Error: `ActiveRecord::RecordNotFound` → 404`
- **Note Ownership:** Note must belong to the specified trip
  - Enforced by: `@trip.notes.find(params[:id])` in `set_note` before_action
  - Error: `ActiveRecord::RecordNotFound` → 404

### 9.3. UI State Conditions

**Edit Mode Activation:**
- Edit mode can be activated if:
  - Note item is in display mode
  - User is authenticated (implicit, as page requires auth)
  - No other note in the list is currently being edited (optional constraint)

**Delete Confirmation:**
- Delete action requires:
  - User confirmation via dialog
  - User is authenticated
  - Note exists and belongs to user's trip

**Form Submission State:**
- Form can be submitted if:
  - Edit mode is active
  - Form is not currently submitting (prevents double-submission)
  - Content passes client-side validation

### 9.4. Error State Conditions

**Validation Error Display:**
- Errors are shown when:
  - Server returns 422 status with validation errors
  - Errors are displayed inline below the textarea field
  - Edit mode remains active to allow correction

**Network Error Display:**
- Network errors are shown when:
  - Request fails due to network issues
  - Server is unreachable
  - Request times out

**Not Found Error Display:**
- 404 errors are shown when:
  - Note doesn't exist
  - Note doesn't belong to user's trip
  - Trip doesn't exist or doesn't belong to user

## 10. Error Handling

### 10.1. Validation Errors

**Scenario:** User submits form with invalid content (empty or too long)

**Handling:**
1. Server validates content and returns 422 status
2. Turbo Stream response re-renders notes list with error messages
3. Note item shows validation errors below textarea
4. Edit mode remains active
5. User can correct errors and resubmit

**Error Display:**
- Errors are shown using the `shared/error_message` partial
- Errors appear below the textarea field
- Error messages are specific (e.g., "Content can't be blank", "Content is too long")

### 10.2. Authorization Errors

**Scenario:** User attempts to edit/delete a note they don't own

**Handling:**
1. Server raises `ActiveRecord::RecordNotFound`
2. `ApplicationController#handle_not_found` catches the exception
3. Returns 404 status
4. For HTML: Redirects to root with flash alert "Resource not found"
5. For Turbo Stream: Returns error response (handled by Turbo)

**Error Display:**
- Flash message: "Resource not found"
- User is redirected or shown error toast

### 10.3. Network Errors

**Scenario:** Network request fails (timeout, connection error)

**Handling:**
1. Turbo detects network error
2. Turbo's default error handling shows error message
3. Optional: Custom error handler can be added via Stimulus controller
4. User can retry the operation

**Error Display:**
- Browser default error or custom error toast
- Form remains in current state (edit mode if editing)
- User can retry submission

### 10.4. Server Errors

**Scenario:** Unexpected server error (500 Internal Server Error)

**Handling:**
1. Server returns 500 status
2. `ApplicationController#handle_server_error` handles the error (if implemented)
3. Error is logged on server
4. User sees generic error message

**Error Display:**
- Flash message: "An unexpected error occurred"
- User is redirected or shown error toast
- Error details are logged server-side (not shown to user)

### 10.5. Delete Confirmation Cancellation

**Scenario:** User clicks delete but cancels confirmation

**Handling:**
1. JavaScript `confirm()` returns `false`
2. Delete request is not sent
3. No UI changes occur
4. Note remains unchanged

**Error Display:**
- None (operation cancelled by user)

### 10.6. Concurrent Modification

**Scenario:** User edits a note that was deleted by another session (unlikely in single-user context, but possible)

**Handling:**
1. Update request returns 404 (note no longer exists)
2. Error is handled as authorization error
3. Notes list is refreshed to show current state

**Error Display:**
- Flash message: "Resource not found"
- Notes list is updated to reflect current state

## 11. Implementation Steps

### Step 1: Create Stimulus Controller for Note Editing

1. Create `app/javascript/controllers/note_edit_controller.js`
2. Implement controller with:
   - `isEditing` state (Boolean)
   - `originalContent` state (String)
   - `edit()` method to enter edit mode
   - `cancel()` method to exit edit mode and restore content
   - `handleSubmit()` method to handle form submission
   - `handleSuccess()` method to handle successful update (via Turbo Stream)
   - `handleError()` method to handle errors

### Step 2: Update Note Item Partial

1. Modify `app/views/trips/_note_item.html.erb`:
   - Add Stimulus controller data attribute: `data-controller="note-edit"`
   - Wrap display mode section in a container with conditional visibility
   - Add Edit and Delete buttons to display mode
   - Add edit form section (initially hidden) with:
     - Form with `form_with` helper targeting update endpoint
     - Textarea field with validation attributes
     - Save and Cancel buttons
     - Error message container
   - Add data targets for Stimulus controller
   - Style buttons consistently with existing UI

### Step 3: Implement Edit Mode Toggle

1. In Stimulus controller, implement `edit()` method:
   - Store original content
   - Hide display mode section
   - Show edit form section
   - Focus textarea
   - Set `isEditing` to `true`

2. Implement `cancel()` method:
   - Restore original content to textarea
   - Hide edit form section
   - Show display mode section
   - Set `isEditing` to `false`

### Step 4: Implement Form Submission

1. In Stimulus controller, implement form submission handling:
   - Prevent default form submission
   - Validate content client-side (optional)
   - Submit form via Turbo
   - Handle Turbo Stream response
   - On success: Let Turbo Stream update the DOM
   - On error: Display errors inline

2. Add form submission event listener:
   - Listen for `turbo:submit-end` event
   - Check response status
   - Handle success/error accordingly

### Step 5: Implement Delete Functionality

1. Add delete button with confirmation:
   - Add delete button in display mode
   - Add `data-action="click->note-edit#delete"` attribute
   - Implement `delete()` method in Stimulus controller:
     - Show confirmation dialog
     - If confirmed: Submit DELETE request via Turbo
     - Handle Turbo Stream response to remove note

2. Use `button_to` helper or Turbo link for delete:
   - Create delete link/button
   - Add `data-turbo-method="delete"` attribute
   - Add confirmation via `data-turbo-confirm` or JavaScript

### Step 6: Style Action Buttons

1. Add Edit and Delete buttons to note item:
   - Use Tailwind CSS classes consistent with existing UI
   - Position buttons in note item header or footer
   - Use icon buttons or text buttons (match existing design)
   - Add hover and focus states
   - Ensure buttons are accessible (ARIA labels)

### Step 7: Handle Turbo Stream Responses

1. Verify Turbo Stream responses work correctly:
   - Update response updates note item
   - Delete response removes note item
   - Error responses show validation errors
   - Flash messages appear in toast container

2. Test edge cases:
   - Empty notes list after deletion
   - Multiple rapid edits
   - Network errors during submission

### Step 8: Add Loading States

1. Implement loading indicators:
   - Disable form buttons during submission
   - Show loading spinner (optional)
   - Prevent double-submission

2. Add to Stimulus controller:
   - `isSubmitting` state
   - Disable buttons when `isSubmitting` is `true`
   - Reset `isSubmitting` on response

### Step 9: Test User Interactions

1. Test edit functionality:
   - Click Edit button → edit mode activates
   - Modify content → changes are visible
   - Click Save → note updates via Turbo Stream
   - Click Cancel → changes are discarded

2. Test delete functionality:
   - Click Delete → confirmation appears
   - Confirm → note is removed via Turbo Stream
   - Cancel → no action taken

3. Test error handling:
   - Submit empty content → validation errors appear
   - Submit content > 10,000 chars → validation errors appear
   - Test network errors (optional, via browser dev tools)

### Step 10: Accessibility Enhancements

1. Add ARIA attributes:
   - `aria-label` for icon buttons
   - `aria-describedby` for error messages
   - `aria-live` region for dynamic updates
   - Proper focus management (focus moves appropriately)

2. Keyboard navigation:
   - Tab order is logical
   - Enter submits form
   - Escape cancels edit mode (optional enhancement)

### Step 11: Polish and Refinement

1. Add visual feedback:
   - Smooth transitions between modes
   - Button hover/focus states
   - Loading indicators during submission

2. Optimize user experience:
   - Auto-focus textarea when entering edit mode
   - Character count indicator (optional)
   - Debounce form submission (optional)

3. Code cleanup:
   - Remove debug code
   - Add comments where needed
   - Ensure consistent code style

### Step 12: Documentation and Testing

1. Update view documentation:
   - Document new functionality in code comments
   - Update any relevant README files

2. Manual testing:
   - Test all user interactions
   - Test error scenarios
   - Test on different browsers
   - Test responsive design (mobile/tablet)

3. Integration testing (if applicable):
   - Write/update RSpec tests for controller actions
   - Test Turbo Stream responses
   - Test authorization scenarios

