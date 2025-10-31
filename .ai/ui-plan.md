# UI Architecture for Travel Planner

## 1. UI Structure Overview

The Travel Planner application will be a full-stack Ruby on Rails application with a modern, responsive user interface powered by Hotwire (Turbo and Stimulus). The UI architecture is designed to provide a seamless, single-page-application-like experience while adhering strictly to RESTful principles.

The visual foundation will be Google's Material Design, implemented using the `material-tailwind` library. The entire application is built with a mobile-first approach, ensuring a consistent and accessible experience across all devices. The client-side is stateless, relying on the server as the single source of truth, with Hotwire managing UI updates and navigation.

## 2. View List

### View: Application Layout
- **View Path:** `app/views/layouts/application.html.erb`
- **Main Purpose:** Provides the main structure for the application, including the navigation sidebar and content area.
- **Key Information to Display:** Navigation links, flash messages (toasts/snackbars), and the main content of the current view.
- **Key View Components:**
  - Responsive Sidebar (persistent on desktop, collapses to a hamburger menu on mobile).
  - Main content `yield` area.
  - Toast/Snackbar container for flash messages.
- **UX, Accessibility, and Security:**
  - **UX:** Ensures consistent navigation and layout across the entire application.
  - **Accessibility:** Uses semantic HTML (`<nav>`, `<main>`) for clear document structure. The sidebar will be keyboard-navigable.
  - **Security:** N/A (Layout container).

### View: Dashboard (Trips List)
- **View Path:** `GET /trips`
- **Main Purpose:** To display a list of the user's travel trips and provide an entry point for creating a new trip. This is the primary landing page for authenticated users.
- **Key Information to Display:**
  - A list of trip cards, each showing the destination and dates.
  - An empty state message if the user has no trips.
- **Key View Components:**
  - Material Design Cards to represent each trip.
  - A Floating Action Button (FAB) to navigate to the "New Trip" form.
  - Empty State component with a clear call-to-action.
- **UX, Accessibility, and Security:**
  - **UX:** Provides a clear, scannable overview of all trips. The FAB offers a clear, primary action.
  - **Accessibility:** Uses `<ul>` for the list of trips and ensures cards are focusable. The FAB will have an appropriate `aria-label`.
  - **Security:** The controller action will be scoped to only show trips belonging to the `current_user`.

### View: New/Edit Trip Form
- **View Path:** `GET /trips/new`, `GET /trips/:id/edit`
- **Main Purpose:** To allow users to create a new trip or update an existing one.
- **Key Information to Display:** A form with fields for destination, start date, end date, and budget.
- **Key View Components:**
  - Semantic HTML form (`<form>`, `<label>`, `<input>`).
  - Submit button.
  - Inline error message containers for validation.
- **UX, Accessibility, and Security:**
  - **UX:** On `422 Unprocessable Entity` response, the form is re-rendered with user input preserved and inline errors are displayed via Turbo Streams, preventing data loss.
  - **Accessibility:** All form fields will have associated `<label>`s.
  - **Security:** Uses strong parameters in the controller to prevent mass assignment vulnerabilities. The "edit" route is protected to ensure users can only edit their own trips.

### View: Trip Detail
- **View Path:** `GET /trips/:id`
- **Main Purpose:** To provide a detailed view of a single trip, including its associated notes and generated plans.
- **Key Information to Display:**
  - Trip details (destination, dates).
  - A tabbed interface for "Notes" and "Generated Plans."
- **Key View Components:**
  - Tab component to switch between content.
  - **Notes Tab:** A list of notes and a form to add a new note.
  - **Generated Plans Tab:** A list of generated plans with their status indicated by colored Material Design Chips, and a "Generate Plan" button.
- **UX, Accessibility, and Security:**
  - **UX:** Tabs organize related information cleanly. Asynchronous plan generation status is updated in real-time via Turbo Streams, providing immediate feedback without a page reload.
  - **Accessibility:** Tabs will be implemented with proper ARIA roles (`tablist`, `tab`, `tabpanel`).
  - **Security:** The controller action ensures a user can only view their own trip details. A `404 Not Found` is returned otherwise.

### View: Profile & Preferences
- **View Path:** `GET /profile` (custom route), linking to `GET /preferences/edit` and Devise's `edit_user_registration_path`.
- **Main Purpose:** A centralized location for users to manage their account settings and travel preferences.
- **Key Information to Display:** A tabbed interface to switch between "Account" and "Preferences."
- **Key View Components:**
  - Tab component.
  - **Account Tab:** Content for managing email/password (links to Devise).
  - **Preferences Tab:** A form for setting travel preferences (accommodation, activities, etc.).
- **UX, Accessibility, and Security:**
  - **UX:** Consolidates all user settings into one easy-to-find location.
  - **Accessibility:** Tabs will use proper ARIA roles. The preferences form will follow accessibility best practices with labels for all inputs.
  - **Security:** All actions are scoped to the `current_user`.

## 3. User Journey Map

The primary user journey involves creating a trip and generating an AI plan.

1.  **Login:** The user signs into the application.
2.  **Dashboard:** The user lands on the Dashboard (`/trips`).
    - **Scenario A (New User):** The user sees an "empty state" view with a prominent "Create your first trip" button.
    - **Scenario B (Existing User):** The user sees a list of their existing trips displayed as Material Design Cards.
3.  **Initiate Trip Creation:** The user clicks the Floating Action Button (FAB).
4.  **New Trip Form:** The user is navigated to the New Trip form (`/trips/new`), fills in the details, and submits.
5.  **Redirect to Trip Detail:** Upon successful creation (`POST /trips`), the user is redirected to the Trip Detail page (`/trips/:id`) for the newly created trip. A "Trip was successfully created" toast message appears.
6.  **View Generated Plans:** On the Trip Detail page, the user clicks the "Generated Plans" tab.
7.  **Request Plan:** The user clicks the "Generate Plan" button.
8.  **Async Update:** The UI immediately shows a new plan in the list with a "generating" status Chip. This update is delivered via a Turbo Stream.
9.  **Plan Completion:** When the plan is ready, a second Turbo Stream update is pushed from the server. The Chip's status changes to "completed" or "failed," providing the user with real-time feedback.

## 4. Layout and Navigation Structure

Navigation is centered around a responsive sidebar that is always visible on desktop and collapses into a hamburger menu on mobile devices.

- **Primary Navigation (Sidebar):**
  - **My Trips:** Links to the Dashboard (`/trips`).
  - **Profile & Preferences:** Links to the unified settings page (`/profile`).
  - **Sign Out:** Terminates the user session.

- **Contextual Navigation:**
  - **Floating Action Button (Dashboard):** Navigates to the New Trip form (`/trips/new`).
  - **Trip Cards (Dashboard):** Each card links to the corresponding Trip Detail page (`/trips/:id`).
  - **Tabs (Trip Detail & Profile Pages):** Allow users to switch between related sections of content without changing the URL.

## 5. Key Components

- **Responsive Sidebar:** The core navigation element. Persistent on large screens for quick access and collapsed on small screens to maximize content visibility.
- **Material Design Card:** Used to display summary information for list items, such as trips on the Dashboard.
- **Floating Action Button (FAB):** A prominent, circular button used for the primary positive action on a screen, such as creating a new trip.
- **Material Design Chip:** A compact element used to represent status (`generating`, `completed`, `failed`) with distinct colors for immediate visual feedback.
- **Toast/Snackbar:** Used for displaying brief, non-intrusive flash messages to the user (e.g., success or error notifications).
- **Tabs:** Used to organize content within a single view, such as separating "Notes" and "Generated Plans" on the Trip Detail page.
- **Empty State Component:** A view shown when a list is empty. It communicates the lack of data and provides a clear call-to-action to guide the user's next step.
