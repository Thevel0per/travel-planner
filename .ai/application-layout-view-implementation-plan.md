# View Implementation Plan: Application Layout

## 1. Overview

The Application Layout view serves as the foundational structure for the entire TravelPlanner application. It provides a consistent navigation experience through a responsive sidebar that adapts to different screen sizes, manages flash message display through toast notifications, and wraps all page content in a semantic HTML structure. The layout ensures that authenticated users have easy access to primary navigation (My Trips, Profile & Preferences) and can sign out, while maintaining accessibility standards and a modern Material Design aesthetic.

## 2. View Routing

The Application Layout is automatically applied to all views through Rails' layout system. It is defined at `app/views/layouts/application.html.erb` and is the default layout for all authenticated pages. The layout is conditionally rendered based on user authentication status, with navigation elements only appearing when `user_signed_in?` returns true.

## 3. Component Structure

```
Application Layout (application.html.erb)
├── Navigation Sidebar (_navigation_sidebar.html.erb)
│   ├── Sidebar Header (Logo/Title)
│   ├── Navigation Links List
│   │   ├── My Trips Link
│   │   ├── Profile & Preferences Link
│   │   └── Sign Out Button
│   └── Mobile Menu Toggle Button (hamburger icon)
├── Main Content Area (yield)
│   └── [Dynamic content from child views]
└── Toast Container (_toast_container.html.erb)
    ├── Success Toast (_success_toast.html.erb)
    └── Error Toast (_error_toast.html.erb)
```

## 4. Component Details

### Navigation Sidebar (_navigation_sidebar.html.erb)

- **Component description:** A responsive navigation sidebar that provides primary navigation links for authenticated users. On desktop screens (≥1024px), the sidebar is persistent and visible. On mobile screens (<1024px), it collapses into a hamburger menu that can be toggled open/closed. The sidebar uses Material Design styling and implements proper ARIA attributes for accessibility.

- **Main elements:**
  - `<nav>` element with `role="navigation"` and `aria-label="Main navigation"`
  - Sidebar container with responsive classes (hidden on mobile, visible on desktop)
  - Mobile overlay backdrop (visible when mobile menu is open)
  - Hamburger menu toggle button (visible only on mobile)
  - Sidebar header section with application logo/title
  - Unordered list (`<ul>`) for navigation links with `role="list"`
  - Navigation link items (`<li role="none">`) containing anchor tags or button elements
  - Sign out button/link with proper form submission handling

- **Handled interactions:**
  - Click on hamburger menu button toggles mobile sidebar visibility
  - Click on overlay backdrop closes mobile sidebar
  - Keyboard navigation (Tab, Enter, Escape) for sidebar and links
  - Escape key closes mobile sidebar
  - Click on navigation links navigates to respective pages
  - Click on sign out button submits DELETE request to destroy user session

- **Handled validation:**
  - Sidebar only renders when `user_signed_in?` is true
  - Active link highlighting based on current route (using `current_page?` helper)
  - Mobile menu closes automatically on navigation (via Turbo navigation events)

- **Types:** No custom DTOs or ViewModels required. Uses Rails helper methods:
  - `user_signed_in?` - Devise helper to check authentication status
  - `current_user` - Devise helper to access current user (if needed)
  - `current_page?` - Rails helper to determine active navigation link
  - Route helpers: `trips_path`, `profile_path`, `destroy_user_session_path`

- **Props:** No props required. Component receives all data from Rails helpers and view context.

### Toast Container (_toast_container.html.erb)

- **Component description:** A container component that manages the display of flash messages (notice and alert) as toast notifications. The container positions toasts in the top-right corner of the viewport and automatically dismisses them after a set duration. Toasts use Material Design styling with distinct visual indicators for success (green checkmark) and error (red alert icon).

- **Main elements:**
  - Container div with fixed positioning (top-right corner)
  - Success toast component (rendered when `flash[:notice]` is present)
  - Error toast component (rendered when `flash[:alert]` is present)
  - Each toast contains:
    - Icon SVG (success or error indicator)
    - Message text from flash hash
    - Optional close button for manual dismissal

- **Handled interactions:**
  - Automatic dismissal after 5 seconds (via Stimulus controller)
  - Manual dismissal via close button click
  - Click outside toast does not dismiss (toasts only dismiss via timer or close button)
  - Multiple toasts stack vertically when both notice and alert are present

- **Handled validation:**
  - Toast only renders when corresponding flash key is present (`flash[:notice]` or `flash[:alert]`)
  - Flash messages are automatically cleared after display (Rails default behavior)
  - Empty flash messages are not rendered

- **Types:** No custom DTOs or ViewModels required. Uses Rails flash hash:
  - `flash[:notice]` - String message for success notifications
  - `flash[:alert]` - String message for error notifications

- **Props:** No props required. Component reads directly from Rails flash hash.

### Success Toast (_success_toast.html.erb)

- **Component description:** A reusable partial that displays a success notification toast with a green checkmark icon. Used within the toast container to display `flash[:notice]` messages.

- **Main elements:**
  - Fixed-position container div with Material Design styling
  - Icon SVG (checkmark in green)
  - Message text container
  - Optional close button (X icon)

- **Handled interactions:**
  - Auto-dismiss after 5 seconds
  - Manual dismiss via close button
  - Click on toast does not dismiss (prevents accidental dismissal)

- **Handled validation:**
  - Only renders when `flash[:notice]` is present and not empty

- **Types:** No custom types required. Uses `flash[:notice]` string.

- **Props:** No props required. Reads from Rails flash hash.

### Error Toast (_error_toast.html.erb)

- **Component description:** A reusable partial that displays an error notification toast with a red alert icon. Used within the toast container to display `flash[:alert]` messages.

- **Main elements:**
  - Fixed-position container div with Material Design styling
  - Icon SVG (alert circle in red)
  - Message text container
  - Optional close button (X icon)

- **Handled interactions:**
  - Auto-dismiss after 5 seconds (longer than success toasts - 7 seconds)
  - Manual dismiss via close button
  - Click on toast does not dismiss

- **Handled validation:**
  - Only renders when `flash[:alert]` is present and not empty

- **Types:** No custom types required. Uses `flash[:alert]` string.

- **Props:** No props required. Reads from Rails flash hash.

## 5. Types

No custom DTOs or ViewModels are required for the Application Layout view. The layout uses standard Rails and Devise helpers:

- **Rails Flash Hash:** Standard Rails flash message storage
  - `flash[:notice]` - String: Success message text
  - `flash[:alert]` - String: Error message text

- **Rails Route Helpers:** Standard Rails route helpers for navigation
  - `trips_path` - String: Path to trips index page
  - `profile_path` - String: Path to profile page
  - `destroy_user_session_path` - String: Path for sign out action (DELETE request)

- **Devise Helpers:** Standard Devise authentication helpers
  - `user_signed_in?` - Boolean: Returns true if user is authenticated
  - `current_user` - User object: Current authenticated user (optional, not strictly needed for layout)

- **Rails URL Helpers:** For active link detection
  - `current_page?` - Boolean: Returns true if provided path matches current page

## 6. State Management

State management for the Application Layout is handled through:

1. **Server-Side State (Rails):**
   - Authentication state via Devise (`user_signed_in?`)
   - Flash messages via Rails flash hash
   - Current route via Rails routing helpers

2. **Client-Side State (Stimulus Controller):**
   - A custom Stimulus controller `sidebar_controller.js` manages mobile sidebar visibility state
   - State variables:
     - `isOpen` (Boolean): Tracks whether mobile sidebar is open or closed
   - Controller targets:
     - `sidebar` (Element): The sidebar navigation element
     - `overlay` (Element): The mobile overlay backdrop
     - `toggleButton` (Element): The hamburger menu toggle button
   - Controller actions:
     - `toggle()`: Toggles mobile sidebar open/closed state
     - `close()`: Closes mobile sidebar
     - `handleEscape()`: Closes sidebar on Escape key press

3. **Toast Auto-Dismiss State (Stimulus Controller):**
   - A custom Stimulus controller `toast_controller.js` manages toast visibility and auto-dismiss
   - State variables:
     - `timeoutId` (Number): Stores setTimeout ID for auto-dismiss
   - Controller targets:
     - `toast` (Element): The toast element
   - Controller actions:
     - `dismiss()`: Manually dismisses the toast
     - `startTimer()`: Starts auto-dismiss timer (5 seconds for notice, 7 seconds for alert)
     - `clearTimer()`: Clears auto-dismiss timer

## 7. API Integration

The Application Layout does not directly integrate with API endpoints. However, it handles:

1. **Sign Out Action:**
   - Uses Rails `link_to` helper with `method: :delete` to submit DELETE request
   - Target endpoint: `destroy_user_session_path` (Devise route)
   - No request body required
   - Response: Redirects to root or login page after successful sign out

2. **Navigation Links:**
   - All navigation uses standard Rails route helpers that generate proper URLs
   - Navigation leverages Turbo Drive for seamless page transitions
   - No API calls required for navigation

3. **Flash Messages:**
   - Flash messages are set server-side in controllers
   - Displayed client-side via the layout view
   - No API integration required

## 8. User Interactions

### Desktop Navigation

1. **Click on "My Trips" link:**
   - User clicks navigation link
   - Turbo Drive navigates to `/trips`
   - Active link styling updates to highlight "My Trips"
   - Page content updates via Turbo without full page reload

2. **Click on "Profile & Preferences" link:**
   - User clicks navigation link
   - Turbo Drive navigates to `/profile`
   - Active link styling updates to highlight "Profile & Preferences"
   - Page content updates via Turbo

3. **Click on "Sign Out" button:**
   - User clicks sign out button
   - DELETE request submitted to `destroy_user_session_path`
   - Server destroys user session
   - User redirected to root or login page
   - Sidebar navigation disappears (user no longer authenticated)

### Mobile Navigation

1. **Open mobile menu:**
   - User clicks hamburger menu icon
   - Sidebar slides in from left
   - Overlay backdrop appears
   - Sidebar becomes visible and interactive

2. **Close mobile menu:**
   - User clicks overlay backdrop
   - OR user presses Escape key
   - OR user clicks close button (if implemented)
   - Sidebar slides out to left
   - Overlay backdrop disappears

3. **Navigate from mobile menu:**
   - User clicks any navigation link
   - Navigation occurs via Turbo Drive
   - Mobile sidebar automatically closes after navigation
   - Active link styling updates

### Toast Notifications

1. **View success toast:**
   - Flash notice message appears as toast in top-right corner
   - Toast displays green checkmark icon and message text
   - Toast auto-dismisses after 5 seconds
   - User can manually dismiss by clicking close button

2. **View error toast:**
   - Flash alert message appears as toast in top-right corner
   - Toast displays red alert icon and message text
   - Toast auto-dismisses after 7 seconds
   - User can manually dismiss by clicking close button

3. **Multiple toasts:**
   - If both notice and alert are present, both toasts display
   - Toasts stack vertically (alert above notice)
   - Each toast dismisses independently

## 9. Conditions and Validation

### Authentication State

1. **User is authenticated (`user_signed_in? == true`):**
   - Sidebar navigation renders and is visible
   - All navigation links are accessible
   - Sign out button is functional

2. **User is not authenticated (`user_signed_in? == false`):**
   - Sidebar navigation does not render
   - Layout still renders (for login/registration pages)
   - Toast notifications still function

### Active Link Highlighting

1. **Current page is "/trips" or "/trips/:id":**
   - "My Trips" link receives active styling (e.g., blue text, underline)
   - Other links receive inactive styling

2. **Current page is "/profile" or "/preferences":**
   - "Profile & Preferences" link receives active styling
   - Other links receive inactive styling

3. **Current page is not a navigation destination:**
   - No links receive active styling
   - All links display in inactive state

### Responsive Behavior

1. **Desktop viewport (≥1024px width):**
   - Sidebar is always visible (persistent)
   - Hamburger menu button is hidden
   - Overlay backdrop is hidden
   - Sidebar width is fixed (e.g., 256px)

2. **Mobile viewport (<1024px width):**
   - Sidebar is hidden by default
   - Hamburger menu button is visible
   - Sidebar toggles via hamburger button
   - Overlay backdrop appears when sidebar is open

### Flash Message Validation

1. **Flash notice present:**
   - Success toast renders
   - Toast displays message text
   - Toast auto-dismisses after 5 seconds

2. **Flash alert present:**
   - Error toast renders
   - Toast displays message text
   - Toast auto-dismisses after 7 seconds

3. **No flash messages:**
   - Toast container does not render
   - No toast elements in DOM

## 10. Error Handling

### Navigation Errors

1. **Route not found:**
   - Standard Rails 404 handling
   - User sees 404 page (not handled by layout)
   - Navigation remains functional

2. **Unauthorized access:**
   - Controller handles authorization
   - User redirected with flash alert
   - Layout displays error toast

### Sign Out Errors

1. **Sign out fails:**
   - Server-side error handling (Devise)
   - Flash alert set with error message
   - Layout displays error toast
   - User remains authenticated

### Toast Display Errors

1. **Flash message is nil or empty:**
   - Toast component checks for presence
   - Toast does not render if message is empty
   - No error state, graceful degradation

2. **Multiple rapid flash messages:**
   - Each flash message type renders independently
   - Toasts stack vertically
   - No conflicts or overlapping issues

### Responsive Layout Errors

1. **JavaScript disabled:**
   - Mobile sidebar remains hidden (CSS only)
   - Desktop sidebar remains visible (CSS only)
   - Navigation links still functional (server-side)
   - Toast auto-dismiss does not work (manual close still works if implemented)

2. **Stimulus controller fails to load:**
   - Sidebar toggle functionality disabled
   - Desktop sidebar remains visible (CSS fallback)
   - Mobile users can still access navigation if hamburger button uses CSS-only solution
   - Toast auto-dismiss disabled (toasts remain visible until page refresh)

## 11. Implementation Steps

### Step 1: Create Stimulus Sidebar Controller

1. Create `app/javascript/controllers/sidebar_controller.js`
2. Implement controller with targets: `sidebar`, `overlay`, `toggleButton`
3. Add `toggle()` action to open/close sidebar
4. Add `close()` action to close sidebar
5. Add keyboard event handler for Escape key
6. Add Turbo navigation listener to auto-close sidebar on navigation

### Step 2: Create Stimulus Toast Controller

1. Create `app/javascript/controllers/toast_controller.js`
2. Implement controller with target: `toast`
3. Add `connect()` lifecycle method to start auto-dismiss timer
4. Add `dismiss()` action for manual dismissal
5. Add `startTimer()` and `clearTimer()` methods
6. Configure different timeout durations for notice (5s) and alert (7s)

### Step 3: Create Navigation Sidebar Partial

1. Create `app/views/shared/_navigation_sidebar.html.erb`
2. Add conditional rendering based on `user_signed_in?`
3. Implement desktop sidebar structure with Material Design classes
4. Implement mobile hamburger button
5. Implement mobile overlay backdrop
6. Add navigation links: My Trips, Profile & Preferences, Sign Out
7. Add active link detection using `current_page?` helper
8. Add proper ARIA attributes for accessibility
9. Connect Stimulus sidebar controller with `data-controller="sidebar"`

### Step 4: Create Toast Container Partial

1. Create `app/views/shared/_toast_container.html.erb`
2. Add conditional rendering for `flash[:notice]` and `flash[:alert]`
3. Render success toast partial when notice is present
4. Render error toast partial when alert is present
5. Position container in top-right corner with fixed positioning

### Step 5: Create Success Toast Partial

1. Create `app/views/shared/_success_toast.html.erb`
2. Add Material Design styling classes
3. Include green checkmark SVG icon
4. Display `flash[:notice]` message text
5. Add optional close button
6. Connect Stimulus toast controller with appropriate timeout

### Step 6: Create Error Toast Partial

1. Create `app/views/shared/_error_toast.html.erb`
2. Add Material Design styling classes
3. Include red alert circle SVG icon
4. Display `flash[:alert]` message text
5. Add optional close button
6. Connect Stimulus toast controller with appropriate timeout

### Step 7: Update Application Layout

1. Open `app/views/layouts/application.html.erb`
2. Remove existing inline flash message HTML (lines 32-65)
3. Add navigation sidebar partial render: `<%= render 'shared/navigation_sidebar' if user_signed_in? %>`
4. Add main content wrapper with proper semantic structure
5. Add toast container partial render: `<%= render 'shared/toast_container' %>`
6. Ensure main content area uses `<main>` element with proper layout classes
7. Add responsive layout wrapper to accommodate sidebar

### Step 8: Add CSS for Responsive Sidebar

1. Update `app/assets/stylesheets/application.css` or Tailwind configuration
2. Add responsive classes for sidebar visibility (hidden on mobile, visible on desktop)
3. Add transition classes for smooth sidebar slide animations
4. Add overlay backdrop styling
5. Ensure proper z-index layering (sidebar, overlay, toasts)

### Step 9: Register Stimulus Controllers

1. Ensure `app/javascript/controllers/index.js` exports sidebar controller
2. Ensure `app/javascript/controllers/index.js` exports toast controller
3. Verify controllers are properly registered with Stimulus

### Step 10: Test Navigation Functionality

1. Test desktop sidebar visibility and persistence
2. Test mobile hamburger menu toggle
3. Test navigation link clicks and active state highlighting
4. Test sign out functionality
5. Test keyboard navigation (Tab, Enter, Escape)
6. Test responsive breakpoints (desktop vs mobile)

### Step 11: Test Toast Functionality

1. Test success toast display with `flash[:notice]`
2. Test error toast display with `flash[:alert]`
3. Test auto-dismiss timing (5s for notice, 7s for alert)
4. Test manual dismissal via close button
5. Test multiple toasts stacking
6. Test toast behavior when JavaScript is disabled

### Step 12: Accessibility Testing

1. Test keyboard navigation through sidebar links
2. Test ARIA attributes with screen reader
3. Test focus management when sidebar opens/closes
4. Test escape key functionality
5. Verify semantic HTML structure (`<nav>`, `<main>`, `<ul>`, etc.)
6. Test color contrast for text and icons

### Step 13: Polish and Refinement

1. Add smooth transitions for sidebar animations
2. Add smooth fade-in/fade-out for toast notifications
3. Ensure proper Material Design styling consistency
4. Verify mobile touch targets are appropriately sized (≥44x44px)
5. Add loading states if needed
6. Review and optimize CSS for performance

