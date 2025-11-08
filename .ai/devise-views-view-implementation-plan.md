# View Implementation Plan: Devise Authentication Views

## 1. Overview

This implementation plan covers updating all Devise-provided authentication views to match the TravelPlanner application's Material Design aesthetic and component architecture. The views include user registration, email confirmation, login, password reset, and resend confirmation instructions. All views will use the application's shared form components, Material Design styling via `material-tailwind`, and toast notifications for flash messages. These views are accessible to unauthenticated users and therefore do not display the navigation sidebar.

## 2. View Routing

All Devise views are automatically routed through the `devise_for :users` configuration in `config/routes.rb`. The views will be located at:

- **Registration:** `GET /users/sign_up` (new), `POST /users` (create)
- **Login:** `GET /users/sign_in` (new), `POST /users/sign_in` (create)
- **Email Confirmation:** `GET /users/confirmation?confirmation_token=...` (show), `GET /users/confirmation/new` (new), `POST /users/confirmation` (create)
- **Password Reset:** `GET /users/password/new` (new), `POST /users/password` (create), `GET /users/password/edit?reset_password_token=...` (edit), `PUT /users/password` (update)

Views will be generated in `app/views/devise/` directory using `rails generate devise:views`.

## 3. Component Structure

```
Devise Views Root
├── registrations/
│   └── new.html.erb (Registration Form)
│       ├── PageHeader Component
│       ├── Form Wrapper Component
│       │   ├── FormField (email)
│       │   ├── FormField (password)
│       │   ├── FormField (password_confirmation)
│       │   └── FormActions Component
│       └── Link to Sign In
│
├── sessions/
│   └── new.html.erb (Login Form)
│       ├── PageHeader Component
│       ├── Form Wrapper Component
│       │   ├── FormField (email)
│       │   ├── FormField (password)
│       │   ├── Remember Me Checkbox
│       │   └── FormActions Component
│       ├── Link to Sign Up
│       └── Link to Forgot Password
│
├── confirmations/
│   ├── new.html.erb (Resend Confirmation Instructions)
│   │   ├── PageHeader Component
│   │   ├── Form Wrapper Component
│   │   │   ├── FormField (email)
│   │   │   └── FormActions Component
│   │   └── Link to Sign In
│   └── show.html.erb (Confirmation Success Page)
│       ├── PageHeader Component
│       ├── Success Message
│       └── Link to Sign In
│
└── passwords/
    ├── new.html.erb (Forgot Password Form)
    │   ├── PageHeader Component
    │   ├── Form Wrapper Component
    │   │   ├── FormField (email)
    │   │   └── FormActions Component
    │   └── Link to Sign In
    └── edit.html.erb (Reset Password Form)
        ├── PageHeader Component
        ├── Form Wrapper Component
        │   ├── FormField (password)
        │   ├── FormField (password_confirmation)
        │   └── FormActions Component
        └── Link to Sign In
```

**Shared Component Locations:**
- `app/views/shared/_page_header.html.erb` - Page header with title
- `app/views/shared/_form.html.erb` - Form wrapper with Turbo support
- `app/views/shared/_form_field.html.erb` - Reusable form field component
- `app/views/shared/_form_actions.html.erb` - Form action buttons
- `app/views/shared/_error_message.html.erb` - Error message display
- `app/views/shared/_toast_container.html.erb` - Toast notification container

## 4. Component Details

### Registration Form (registrations/new.html.erb)

- **Component description:** The user registration form that allows new users to create an account with email and password. Uses shared form components and Material Design styling. Displays validation errors inline for each field.

- **Main elements:**
  - Container div with `data-controller="material-tailwind"` for Material Tailwind initialization
  - Semantic `<main>` element with responsive container classes
  - PageHeader component with title "Create Account"
  - Form wrapper using `form_with` helper for Devise's registration resource
  - Three FormField components: email (required), password (required), password_confirmation (required)
  - FormActions component with submit button "Sign Up" and optional cancel link
  - Link to sign in page for existing users

- **Handled interactions:**
  - Form submission via POST to `/users` (handled by Devise)
  - Client-side validation through HTML5 required attributes
  - Server-side validation errors displayed inline via FormField component
  - Success redirect to confirmation instructions page
  - Error handling via flash messages displayed as toasts

- **Handled validation:**
  - Email: Required, must be valid email format, must be unique (checked by Devise)
  - Password: Required, minimum 6 characters, maximum 128 characters (Devise default)
  - Password Confirmation: Required, must match password field
  - All validation errors are displayed inline below each field using the error_message component

- **Types:** None (uses Devise's built-in User model and form helpers)

- **Props:** None (receives `resource` and `resource_name` from Devise controller)

### Login Form (sessions/new.html.erb)

- **Component description:** The user login form that authenticates existing users. Includes email and password fields, optional "Remember Me" checkbox, and links to registration and password reset pages.

- **Main elements:**
  - Container div with `data-controller="material-tailwind"`
  - Semantic `<main>` element with responsive container classes
  - PageHeader component with title "Sign In"
  - Form wrapper using `form_with` helper for Devise's session resource
  - Two FormField components: email (required), password (required)
  - Custom checkbox for "Remember Me" option with Material Design styling
  - FormActions component with submit button "Sign In"
  - Link to sign up page ("Don't have an account? Sign up")
  - Link to forgot password page ("Forgot your password?")

- **Handled interactions:**
  - Form submission via POST to `/users/sign_in` (handled by Devise)
  - Remember Me checkbox toggles session persistence
  - Success redirect to trips index page (root path for authenticated users)
  - Error handling for invalid credentials, unconfirmed email, locked account
  - Multiple failed login attempts handling (temporary lockout)

- **Handled validation:**
  - Email: Required, must be valid email format, must exist in database
  - Password: Required, must match the email's associated password
  - Account must be confirmed (email verified) before login
  - Account must not be locked (after multiple failed attempts)
  - Validation errors displayed via flash messages (not inline, as per Devise convention)

- **Types:** None (uses Devise's built-in authentication)

- **Props:** None (receives `resource` and `resource_name` from Devise controller)

### Resend Confirmation Instructions (confirmations/new.html.erb)

- **Component description:** A form that allows users to request a new confirmation email if they didn't receive the original or if the confirmation token expired.

- **Main elements:**
  - Container div with `data-controller="material-tailwind"`
  - Semantic `<main>` element with responsive container classes
  - PageHeader component with title "Resend Confirmation Instructions"
  - Form wrapper using `form_with` helper for Devise's confirmation resource
  - One FormField component: email (required)
  - FormActions component with submit button "Resend Instructions"
  - Link to sign in page

- **Handled interactions:**
  - Form submission via POST to `/users/confirmation`
  - Success message displayed via toast notification
  - Redirects to sign in page after successful submission

- **Handled validation:**
  - Email: Required, must be valid email format
  - Email must exist in database (Devise handles this silently for security)
  - Validation errors displayed inline below email field

- **Types:** None (uses Devise's built-in confirmation)

- **Props:** None (receives `resource` and `resource_name` from Devise controller)

### Confirmation Success Page (confirmations/show.html.erb)

- **Component description:** A simple success page displayed after a user successfully confirms their email address by clicking the confirmation link.

- **Main elements:**
  - Container div with `data-controller="material-tailwind"`
  - Semantic `<main>` element with responsive container classes
  - PageHeader component with title "Email Confirmed"
  - Success message card with Material Design styling
  - Link to sign in page styled as primary button

- **Handled interactions:**
  - None (static confirmation page)
  - User clicks link to navigate to sign in page

- **Handled validation:**
  - None (confirmation token validated by Devise before rendering)

- **Types:** None (static page)

- **Props:** None (receives confirmation status from Devise)

### Forgot Password Form (passwords/new.html.erb)

- **Component description:** A form that allows users to request a password reset link via email.

- **Main elements:**
  - Container div with `data-controller="material-tailwind"`
  - Semantic `<main>` element with responsive container classes
  - PageHeader component with title "Forgot Your Password?"
  - Form wrapper using `form_with` helper for Devise's password resource
  - One FormField component: email (required)
  - FormActions component with submit button "Send Reset Instructions"
  - Link to sign in page

- **Handled interactions:**
  - Form submission via POST to `/users/password`
  - Success message displayed via toast notification
  - Redirects to sign in page after successful submission

- **Handled validation:**
  - Email: Required, must be valid email format
  - Email must exist in database (Devise handles this silently for security)
  - Validation errors displayed inline below email field

- **Types:** None (uses Devise's built-in password recovery)

- **Props:** None (receives `resource` and `resource_name` from Devise controller)

### Reset Password Form (passwords/edit.html.erb)

- **Component description:** A form that allows users to set a new password after clicking the reset link from their email. Requires a valid reset password token.

- **Main elements:**
  - Container div with `data-controller="material-tailwind"`
  - Semantic `<main>` element with responsive container classes
  - PageHeader component with title "Reset Your Password"
  - Form wrapper using `form_with` helper for Devise's password resource
  - Hidden field for reset_password_token (automatically included by Devise)
  - Two FormField components: password (required), password_confirmation (required)
  - FormActions component with submit button "Update Password"
  - Link to sign in page

- **Handled interactions:**
  - Form submission via PUT to `/users/password`
  - Success redirect to sign in page with success message
  - Error handling for invalid or expired reset token
  - Error handling for password validation failures

- **Handled validation:**
  - Reset Password Token: Required, must be valid and not expired (6 hours default)
  - Password: Required, minimum 6 characters, maximum 128 characters
  - Password Confirmation: Required, must match password field
  - All validation errors displayed inline below each field

- **Types:** None (uses Devise's built-in password reset)

- **Props:** None (receives `resource` and `resource_name` from Devise controller, `reset_password_token` from query params)

## 5. Types

No custom DTOs or ViewModels are required for Devise views. All views use Devise's built-in form helpers and resource objects:

- **`resource`:** The User model instance (new or existing) provided by Devise controllers
- **`resource_name`:** Symbol `:user` representing the Devise resource name
- **Form helpers:** Standard Rails `form_with` helper with Devise's resource routing

Devise handles all authentication logic internally, so no custom type definitions are needed. The views are purely presentational and use shared components that work with any ActiveRecord model.

## 6. State Management

No custom hooks or complex state management is required. Devise views are server-rendered with minimal client-side state:

- **Form state:** Managed by Rails form helpers and server-side validation
- **Flash messages:** Managed by Rails flash hash, displayed via toast notifications
- **Loading states:** Handled by form submission (browser native) and optional loading indicator on submit button via `is_loading` prop in FormActions component
- **Error states:** Managed by Devise's resource object errors, displayed inline via FormField component

The only client-side interactivity is:
- Material Tailwind initialization via Stimulus controller
- Toast notification dismissal via Stimulus toast controller
- Form submission via Turbo (enabled by default in form_with)

## 7. API Integration

Devise views do not integrate with REST API endpoints. They use Devise's standard Rails controller actions:

- **Registration:** `POST /users` → `Devise::RegistrationsController#create`
- **Login:** `POST /users/sign_in` → `Devise::SessionsController#create`
- **Logout:** `DELETE /users/sign_out` → `Devise::SessionsController#destroy`
- **Resend Confirmation:** `POST /users/confirmation` → `Devise::ConfirmationsController#create`
- **Confirm Email:** `GET /users/confirmation?confirmation_token=...` → `Devise::ConfirmationsController#show`
- **Request Password Reset:** `POST /users/password` → `Devise::PasswordsController#create`
- **Reset Password:** `PUT /users/password` → `Devise::PasswordsController#update`

All requests use standard HTML form submissions with Turbo enabled for seamless navigation. Responses are HTML (not JSON), with redirects on success and re-rendered forms with errors on validation failure.

## 8. User Interactions

### Registration Flow (US-001)

1. **User navigates to registration page** (`/users/sign_up`)
   - Sees registration form with email, password, and password confirmation fields
   - Form is empty, no errors displayed

2. **User fills in registration form**
   - Enters email address
   - Enters password (minimum 6 characters)
   - Confirms password (must match)
   - All fields show real-time HTML5 validation feedback

3. **User submits form**
   - If validation passes: Account created, confirmation email sent, redirect to confirmation instructions page with success toast
   - If validation fails: Form re-rendered with inline error messages below each invalid field
   - If email already exists: Error message displayed below email field

4. **User cannot log in until email is verified** (US-001 requirement)
   - Login attempts show "You have to confirm your email address before continuing" error

### Email Verification Flow (US-002)

1. **User receives confirmation email**
   - Email contains unique, single-use confirmation link
   - Link format: `/users/confirmation?confirmation_token=...`

2. **User clicks confirmation link**
   - If token is valid and not expired: Account activated, redirect to confirmation success page
   - If token is invalid or expired: Error message displayed, link to resend confirmation instructions

3. **User views confirmation success page**
   - Sees "Email Confirmed" message
   - Clicks link to navigate to sign in page

4. **User can resend confirmation email** (via `/users/confirmation/new`)
   - Enters email address
   - Submits form
   - Receives success toast notification
   - New confirmation email sent (previous token invalidated)

### Login Flow (US-003)

1. **User navigates to login page** (`/users/sign_in`)
   - Sees login form with email and password fields
   - Optional "Remember Me" checkbox visible
   - Links to registration and password reset visible

2. **User enters credentials and submits**
   - If credentials are valid and email is confirmed: User authenticated, session created, redirect to trips index page (`/trips`)
   - If credentials are invalid: Error toast displayed "Invalid email or password"
   - If email not confirmed: Error toast displayed "You have to confirm your email address before continuing"
   - If account is locked: Error toast displayed "Your account is locked"

3. **Multiple failed login attempts**
   - After configured number of attempts, account temporarily locked
   - Error toast displayed with lockout message
   - User must wait for lockout period or contact support

4. **Remember Me functionality**
   - If checked: Session persists across browser sessions
   - If unchecked: Session expires when browser closes

### Password Reset Flow (US-004)

1. **User navigates to forgot password page** (`/users/password/new`)
   - Sees form with email field
   - Link to sign in page visible

2. **User enters email and submits**
   - If email exists: Password reset email sent, success toast displayed, redirect to sign in page
   - If email doesn't exist: Success message still displayed (security: don't reveal if email exists)
   - Email contains unique, time-limited reset link (valid for 6 hours)

3. **User clicks reset link from email**
   - Link format: `/users/password/edit?reset_password_token=...`
   - If token is valid: Reset password form displayed
   - If token is invalid or expired: Error message displayed, link to request new reset

4. **User sets new password**
   - Enters new password (minimum 6 characters)
   - Confirms new password (must match)
   - Submits form
   - If validation passes: Password updated, success toast displayed, redirect to sign in page
   - If validation fails: Form re-rendered with inline error messages

## 9. Conditions and Validation

### Registration Form Validation

- **Email field:**
  - Required: Yes (HTML5 `required` attribute)
  - Format: Valid email format (HTML5 `type="email"` and Devise validation)
  - Uniqueness: Checked by Devise on server-side
  - Error display: Inline below email field if validation fails

- **Password field:**
  - Required: Yes (HTML5 `required` attribute)
  - Minimum length: 6 characters (Devise default, enforced server-side)
  - Maximum length: 128 characters (Devise default, enforced server-side)
  - Error display: Inline below password field if validation fails

- **Password confirmation field:**
  - Required: Yes (HTML5 `required` attribute)
  - Match: Must exactly match password field (Devise validation)
  - Error display: Inline below password_confirmation field if validation fails

### Login Form Validation

- **Email field:**
  - Required: Yes (HTML5 `required` attribute)
  - Format: Valid email format (HTML5 `type="email"`)
  - Existence: Checked by Devise on server-side
  - Error display: Via flash message (toast) if authentication fails

- **Password field:**
  - Required: Yes (HTML5 `required` attribute)
  - Match: Must match the email's associated password (Devise validation)
  - Error display: Via flash message (toast) if authentication fails

- **Account status checks:**
  - Email must be confirmed (checked by Devise)
  - Account must not be locked (checked by Devise)
  - Error display: Via flash message (toast) if check fails

### Password Reset Validation

- **Reset token:**
  - Required: Yes (must be present in URL query params)
  - Validity: Must be valid and not expired (6 hours default, checked by Devise)
  - Error display: Error message on page if token invalid/expired

- **New password field:**
  - Required: Yes (HTML5 `required` attribute)
  - Minimum length: 6 characters (Devise default)
  - Maximum length: 128 characters (Devise default)
  - Error display: Inline below password field if validation fails

- **Password confirmation field:**
  - Required: Yes (HTML5 `required` attribute)
  - Match: Must exactly match password field
  - Error display: Inline below password_confirmation field if validation fails

### Email Confirmation Validation

- **Confirmation token:**
  - Required: Yes (must be present in URL query params)
  - Validity: Must be valid and not expired (default: no expiration, but configurable)
  - Single-use: Token invalidated after successful confirmation
  - Error display: Error message on page if token invalid/expired

## 10. Error Handling

### Registration Errors

- **Email already registered:**
  - Error message: "Email has already been taken"
  - Display: Inline below email field
  - User action: User can try different email or navigate to login page

- **Password too short:**
  - Error message: "Password is too short (minimum is 6 characters)"
  - Display: Inline below password field
  - User action: User must enter longer password

- **Password confirmation mismatch:**
  - Error message: "Password confirmation doesn't match Password"
  - Display: Inline below password_confirmation field
  - User action: User must re-enter matching password

- **Invalid email format:**
  - Error message: "Email is invalid"
  - Display: Inline below email field
  - User action: User must enter valid email format

### Login Errors

- **Invalid credentials:**
  - Error message: "Invalid email or password" (generic message for security)
  - Display: Toast notification (error toast)
  - User action: User must re-enter correct credentials or use password reset

- **Unconfirmed email:**
  - Error message: "You have to confirm your email address before continuing"
  - Display: Toast notification (error toast)
  - User action: User must click confirmation link in email or request new confirmation

- **Account locked:**
  - Error message: "Your account is locked"
  - Display: Toast notification (error toast)
  - User action: User must wait for lockout period or contact support

- **Session expired:**
  - Error message: "Your session expired. Please sign in again to continue"
  - Display: Toast notification (error toast)
  - User action: User must log in again

### Password Reset Errors

- **Invalid or expired token:**
  - Error message: "Reset password token is invalid" or "Reset password token has expired"
  - Display: Error message on page with link to request new reset
  - User action: User must request new password reset email

- **Password validation failures:**
  - Same as registration password validation errors
  - Display: Inline below respective fields
  - User action: User must correct password according to requirements

### Email Confirmation Errors

- **Invalid or expired token:**
  - Error message: "Confirmation token is invalid" or "Confirmation token has expired"
  - Display: Error message on page with link to resend confirmation
  - User action: User must request new confirmation email

- **Already confirmed:**
  - Error message: "Email was already confirmed, please try signing in"
  - Display: Error message on page with link to sign in
  - User action: User can navigate to sign in page

### General Error Handling

- **Network errors:**
  - Handled by browser/Turbo
  - User sees browser's default error handling
  - Form data preserved (Turbo maintains form state)

- **Server errors (500):**
  - Handled by Rails error handling
  - User redirected to error page or sees error toast
  - Error logged server-side for debugging

- **CSRF token errors:**
  - Handled automatically by Rails
  - User sees "Invalid authenticity token" error
  - User must refresh page and resubmit form

## 11. Implementation Steps

### Step 1: Generate Devise Views

1. Run `rails generate devise:views` in terminal
2. This creates the directory structure `app/views/devise/` with subdirectories:
   - `registrations/`
   - `sessions/`
   - `confirmations/`
   - `passwords/`
3. Verify all view files are created

### Step 2: Create Devise Layout (Optional but Recommended)

1. Create `app/views/layouts/devise.html.erb`
2. Copy structure from `application.html.erb` but remove sidebar render (unauthenticated users)
3. Include Material Tailwind CSS and JavaScript
4. Include toast container for flash messages
5. Set up responsive container for centered forms
6. Configure this layout in `config/initializers/devise.rb`:
   ```ruby
   config.parent_controller = 'ApplicationController'
   ```
   And in `app/controllers/application_controller.rb`:
   ```ruby
   layout :layout_by_resource
   
   private
   
   def layout_by_resource
     devise_controller? ? 'devise' : 'application'
   end
   ```

### Step 3: Implement Registration Form

1. Open `app/views/devise/registrations/new.html.erb`
2. Add container div with `data-controller="material-tailwind"`
3. Add semantic `<main>` element with responsive container classes (`container mx-auto px-4 py-8 max-w-2xl`)
4. Render PageHeader component with title "Create Account"
5. Use `form_with` helper with `resource: resource, url: registration_path(resource_name)`
6. Render FormField components for:
   - `email` (type: 'email', required: true)
   - `password` (type: 'password', required: true)
   - `password_confirmation` (type: 'password', required: true)
7. Render FormActions component with submit_text "Sign Up"
8. Add link to sign in page: `<%= link_to "Already have an account? Sign in", new_session_path(resource_name) %>`
9. Style link with appropriate Material Design classes

### Step 4: Implement Login Form

1. Open `app/views/devise/sessions/new.html.erb`
2. Add container div with `data-controller="material-tailwind"`
3. Add semantic `<main>` element with responsive container classes
4. Render PageHeader component with title "Sign In"
5. Use `form_with` helper with `resource: resource, url: session_path(resource_name)`
6. Render FormField components for:
   - `email` (type: 'email', required: true)
   - `password` (type: 'password', required: true)
7. Add custom "Remember Me" checkbox with Material Design styling:
   ```erb
   <div class="flex items-center">
     <%= check_box_tag :remember_me, "1", false, class: "..." %>
     <%= label_tag :remember_me, "Remember me", class: "..." %>
   </div>
   ```
8. Render FormActions component with submit_text "Sign In"
9. Add links:
   - Link to registration: "Don't have an account? Sign up"
   - Link to password reset: "Forgot your password?"
10. Style all links with appropriate Material Design classes

### Step 5: Implement Resend Confirmation Form

1. Open `app/views/devise/confirmations/new.html.erb`
2. Add container div with `data-controller="material-tailwind"`
3. Add semantic `<main>` element with responsive container classes
4. Render PageHeader component with title "Resend Confirmation Instructions"
5. Use `form_with` helper with `resource: resource, url: confirmation_path(resource_name)`
6. Render FormField component for `email` (type: 'email', required: true)
7. Render FormActions component with submit_text "Resend Instructions"
8. Add link to sign in page
9. Style link with appropriate Material Design classes

### Step 6: Implement Confirmation Success Page

1. Open `app/views/devise/confirmations/show.html.erb` (create if it doesn't exist)
2. Add container div with `data-controller="material-tailwind"`
3. Add semantic `<main>` element with responsive container classes
4. Render PageHeader component with title "Email Confirmed"
5. Add success message card with Material Design styling:
   ```erb
   <div class="rounded-lg bg-green-50 border border-green-200 p-6 mb-6">
     <p class="text-green-800">Your email address has been successfully confirmed. You can now sign in to your account.</p>
   </div>
   ```
6. Add link to sign in page styled as primary button
7. Handle case where confirmation fails (token invalid/expired) with error message and link to resend

### Step 7: Implement Forgot Password Form

1. Open `app/views/devise/passwords/new.html.erb`
2. Add container div with `data-controller="material-tailwind"`
3. Add semantic `<main>` element with responsive container classes
4. Render PageHeader component with title "Forgot Your Password?"
5. Add descriptive text: "Enter your email address and we'll send you a link to reset your password."
6. Use `form_with` helper with `resource: resource, url: password_path(resource_name)`
7. Render FormField component for `email` (type: 'email', required: true)
8. Render FormActions component with submit_text "Send Reset Instructions"
9. Add link to sign in page
10. Style link with appropriate Material Design classes

### Step 8: Implement Reset Password Form

1. Open `app/views/devise/passwords/edit.html.erb`
2. Add container div with `data-controller="material-tailwind"`
3. Add semantic `<main>` element with responsive container classes
4. Render PageHeader component with title "Reset Your Password"
5. Use `form_with` helper with `resource: resource, url: password_path(resource_name), method: :put`
6. Add hidden field for reset_password_token (automatically handled by Devise, but verify)
7. Render FormField components for:
   - `password` (type: 'password', required: true)
   - `password_confirmation` (type: 'password', required: true)
8. Render FormActions component with submit_text "Update Password"
9. Add link to sign in page
10. Handle case where reset token is invalid/expired with error message and link to request new reset

### Step 9: Update FormField Component for Devise Resources

1. Verify `app/views/shared/_form_field.html.erb` works with Devise's resource object
2. Devise uses `resource` instead of model instance variable
3. FormField component should work as-is since it uses `form.object` which works with any form builder
4. Test that error messages display correctly for Devise validation errors

### Step 10: Style All Forms Consistently

1. Ensure all forms use the same container classes and spacing
2. Verify all forms use Material Design button styling via FormActions component
3. Ensure all links use consistent styling (secondary button style or text link style)
4. Verify responsive design works on mobile devices (forms should be full-width on mobile, centered with max-width on desktop)

### Step 11: Test Flash Message Integration

1. Verify toast notifications display for all success/error flash messages
2. Test that Devise's flash messages (`flash[:notice]`, `flash[:alert]`) are properly displayed
3. Verify toast auto-dismissal works correctly
4. Test manual toast dismissal

### Step 12: Test All User Flows

1. **Registration flow:**
   - Test successful registration
   - Test validation errors (invalid email, short password, mismatched passwords)
   - Test duplicate email error
   - Verify confirmation email is sent

2. **Login flow:**
   - Test successful login
   - Test invalid credentials
   - Test unconfirmed email error
   - Test "Remember Me" functionality
   - Test multiple failed login attempts (lockout)

3. **Email confirmation flow:**
   - Test successful confirmation
   - Test invalid/expired token
   - Test resend confirmation instructions
   - Verify confirmation success page displays

4. **Password reset flow:**
   - Test password reset request
   - Test password reset with valid token
   - Test password reset with invalid/expired token
   - Test password validation errors
   - Verify reset email is sent

### Step 13: Accessibility Testing

1. Verify all form fields have proper labels
2. Verify error messages are associated with fields via `aria-describedby`
3. Verify all interactive elements are keyboard accessible
4. Verify focus management is logical
5. Test with screen reader if possible
6. Verify color contrast meets WCAG AA standards

### Step 14: Mobile Responsiveness Testing

1. Test all forms on mobile devices (320px width minimum)
2. Verify forms are readable and usable on small screens
3. Verify buttons and links are appropriately sized for touch targets
4. Verify spacing and padding work well on mobile

### Step 15: Final Polish

1. Review all text for consistency and clarity
2. Verify all links navigate correctly
3. Ensure all error messages are user-friendly
4. Verify Material Design components render correctly
5. Check that all forms match the application's design system
6. Remove any unused Devise view files if generated

