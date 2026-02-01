# Test Plan for Travel Planner Rails Application

## Testing Framework & Tools

### Current Stack
- **RSpec** (~> 7.0) - Primary testing framework
- **FactoryBot Rails** (~> 6.4) - Test data generation
- **Shoulda Matchers** (~> 6.0) - Model validation/association matchers
- **WebMock** (~> 3.23) - HTTP request stubbing for external APIs
- **Devise Test Helpers** - Authentication helpers for request specs

### Missing Tools to Add
- **Capybara** - E2E testing framework for browser interactions
- **Selenium WebDriver** or **Cuprite** - Browser driver (Selenium for real browsers, Cuprite for headless Chrome)
- **Database Cleaner** (optional) - For E2E tests if transactional fixtures don't work
- **SimpleCov** - Code coverage reporting
- **RSpec Retry** - Retry flaky tests in CI

### Test Environment Configuration
- ✅ Eager loading enabled (good for catching load-time errors)
- ✅ Transactional fixtures enabled (fast, isolated tests)
- ✅ CSRF protection disabled in test (appropriate for request specs)
- ⚠️ **Add**: JavaScript driver configuration for system specs
- ⚠️ **Add**: Asset pipeline configuration for E2E tests
- ⚠️ **Add**: Screenshot capture on failures

---

## Test Coverage Areas

### 1. Model Tests (Unit Tests)

**Files to Test:**
- `spec/models/user_spec.rb` ✅ (exists)
- `spec/models/trip_spec.rb` ❌ (missing)
- `spec/models/note_spec.rb` ❌ (missing)
- `spec/models/generated_plan_spec.rb` ❌ (missing)
- `spec/models/user_preference_spec.rb` ❌ (missing)

**Coverage Requirements:**

#### User Model (`app/models/user.rb`)
- ✅ Email validations (presence, uniqueness, format)
- ✅ Password validations (Devise)
- ✅ Associations (has_many :trips, has_one :user_preference)
- ✅ Devise modules (confirmable, recoverable, etc.)

#### Trip Model (`app/models/trip.rb`)
- Validations: name, destination, start_date, end_date, number_of_people
- Custom validation: `end_date_after_start_date`
- Associations: belongs_to :user, has_many :notes, has_many :generated_plans
- Edge cases: end_date equals start_date, end_date before start_date

#### Note Model (`app/models/note.rb`)
- Validations: content presence, max length (10,000)
- Associations: belongs_to :trip
- Scopes: ordered (by created_at asc)

#### GeneratedPlan Model (`app/models/generated_plan.rb`)
- Validations: status inclusion, content presence (conditional), rating range (1-10)
- Custom validation: `rating_only_for_completed`
- Associations: belongs_to :trip
- Scopes: ordered, by_status
- Instance methods: `mark_as_generating!`, `mark_as_completed!`, `mark_as_failed!`
- Status transitions and edge cases

#### UserPreference Model (`app/models/user_preference.rb`)
- Validations: user_id uniqueness, enum validations (budget, accommodation, eating_habits)
- Custom validation: `activities_valid` (comma-separated list validation)
- Associations: belongs_to :user
- Edge cases: invalid activity values, empty activities string

#### Service Objects (`app/models/trips/create.rb`)
- ✅ `spec/models/trips/create_spec.rb` (exists)
- Test initialization, parameter validation, success/failure paths

---

### 2. Request/Controller Tests (Integration Tests)

**Files to Test:**
- `spec/requests/trips_spec.rb` ✅ (exists, comprehensive)
- `spec/requests/trips/notes_spec.rb` ✅ (exists)
- `spec/requests/trips/generated_plans_spec.rb` ✅ (exists)
- `spec/requests/preferences_spec.rb` ✅ (exists)
- `spec/requests/profiles_spec.rb` ❌ (missing)
- `spec/requests/registrations_spec.rb` ❌ (missing)

**Coverage Requirements:**

#### TripsController (`app/controllers/trips_controller.rb`)
- ✅ Authentication (401 for unauthenticated)
- ✅ Authorization (404 for other users' trips)
- ✅ CRUD operations (index, show, new, create, edit, update, destroy)
- ✅ HTML and JSON formats
- ✅ Pagination (index)
- ✅ Strong parameters validation
- ✅ Error handling (422 for validation errors)
- ⚠️ **Add**: Turbo Stream responses (if applicable)
- ⚠️ **Add**: CSRF token validation tests

#### Trips::NotesController (`app/controllers/trips/notes_controller.rb`)
- ✅ Create, update, destroy operations
- ✅ Authentication and authorization
- ✅ Validation error handling
- ⚠️ **Add**: Turbo Stream responses for inline editing

#### Trips::GeneratedPlansController (`app/controllers/trips/generated_plans_controller.rb`)
- ✅ Create, show, update operations
- ✅ Background job enqueueing
- ✅ Status polling (pending, generating, completed, failed)
- ✅ Rating submission
- ⚠️ **Add**: Turbo Stream updates for status changes

#### PreferencesController (`app/controllers/preferences_controller.rb`)
- ✅ Show, update operations
- ✅ Authentication
- ✅ Validation error handling

#### ProfilesController (`app/controllers/profiles_controller.rb`)
- ❌ Show action (display user profile and preferences)
- ❌ Authentication requirement

#### RegistrationsController (`app/controllers/registrations_controller.rb`)
- ❌ Custom registration flow
- ❌ Email confirmation handling
- ❌ Password validation

**Common Patterns:**
- Test both HTML and JSON response formats
- Test 401 for unauthenticated requests
- Test 404 for unauthorized resource access
- Test 422 for validation errors
- Test parameter tampering (user_id override attempts)

---

### 3. Service Object Tests

**Files to Test:**
- `spec/services/generated_plans/generate_spec.rb` ✅ (exists)
- `spec/services/service_result_spec.rb` ✅ (exists)
- `spec/services/trips_query_service_spec.rb` ❌ (missing)

**Coverage Requirements:**

#### GeneratedPlans::Generate (`app/services/generated_plans/generate.rb`)
- ✅ Service initialization and parameter validation
- ✅ Success path (valid trip, preferences, API success)
- ✅ Failure paths (invalid input, API errors, parsing errors)
- ✅ ServiceResult pattern usage
- ✅ External API integration (WebMock stubbing)
- ✅ Background job enqueueing (tested in controller)
- ✅ Data transformation and DTO usage
- ⚠️ **Add**: Retryable vs non-retryable error handling
- ⚠️ **Add**: Edge cases (missing preferences, empty notes)

#### TripsQueryService (`app/services/trips_query_service.rb`)
- ❌ Query building with filters
- ❌ Sorting functionality
- ❌ Pagination integration
- ❌ Parameter validation

#### ServiceResult (`app/services/service_result.rb`)
- ✅ Success/failure methods
- ✅ Data access
- ✅ Error message handling

---

### 4. Background Job Tests

**Files to Test:**
- `spec/jobs/generated_plan_generation_job_spec.rb` ❌ (missing)

**Coverage Requirements:**

#### GeneratedPlanGenerationJob (`app/jobs/generated_plan_generation_job.rb`)
- Job enqueueing (test in controller)
- Job execution with valid parameters
- Job execution with invalid generated_plan_id (should handle gracefully)
- Error handling (service failures, exceptions)
- Status updates (generating → completed/failed)
- Retry logic (if configured)
- Job dependencies (enqueued after plan creation)

**Test Pattern:**
```ruby
include ActiveJob::TestHelper

it 'enqueues job with correct parameters' do
  expect {
    GeneratedPlanGenerationJob.perform_later(generated_plan_id: plan.id, user_id: user.id)
  }.to have_enqueued_job(GeneratedPlanGenerationJob)
end

it 'processes job successfully' do
  perform_enqueued_jobs do
    GeneratedPlanGenerationJob.perform_now(generated_plan_id: plan.id, user_id: user.id)
  end
  expect(plan.reload.status).to eq('completed')
end
```

---

### 5. External API Integration Tests

**Files to Test:**
- `spec/lib/open_router/client_spec.rb` ✅ (exists)
- `spec/lib/open_router/response_spec.rb` ✅ (exists)
- `spec/lib/open_router/error_spec.rb` ✅ (exists)

**Coverage Requirements:**

#### OpenRouter::Client (`lib/open_router/client.rb`)
- ✅ API client initialization
- ✅ Successful API calls
- ✅ Error handling (timeouts, rate limits, network errors)
- ✅ Response parsing and validation
- ✅ Retry logic for transient failures
- ✅ Authentication/authorization with API key
- ✅ WebMock stubbing patterns (via `spec/support/openrouter_helpers.rb`)

**Test Scenarios:**
- Successful chat completion
- Network timeout
- Rate limit (429) with Retry-After header
- Invalid API key (401)
- Server errors (500, 502, 503)
- Invalid JSON response
- Empty response

---

### 6. End-to-End (E2E) Tests - **CRITICAL**

**Files to Create:**
- `spec/system/trips_spec.rb` ❌
- `spec/system/authentication_spec.rb` ❌
- `spec/system/preferences_spec.rb` ❌
- `spec/system/generated_plans_spec.rb` ❌
- `spec/system/notes_spec.rb` ❌

**Coverage Requirements:**

#### User Registration & Authentication
- Sign up flow (form submission, email confirmation)
- Sign in flow (valid/invalid credentials)
- Sign out flow
- Password reset flow
- Email confirmation flow

#### Trip Management Workflow
- Creating a trip (form validation, success, error handling)
- Viewing trips list (pagination, filtering, sorting)
- Viewing trip details (with notes and plans)
- Editing a trip (inline editing, validation)
- Deleting a trip (confirmation, cascade)

#### Notes Workflow
- Creating a note (inline form, Turbo Stream update)
- Editing a note (Stimulus note_edit_controller)
- Deleting a note (confirmation, Turbo Stream removal)

#### User Preferences Workflow
- Setting preferences (form submission, validation)
- Updating preferences (all fields, partial updates)
- Viewing preferences (display current values)

#### AI Plan Generation Workflow
- Initiating generation (button click, job enqueueing)
- Viewing pending status (polling, status display)
- Viewing completed plan (accordion display, tabs navigation)
- Rating a plan (Stimulus star_rating_controller, auto-submit)

#### Hotwire/Turbo Interactions
- Turbo Drive navigation (page transitions, no full reload)
- Turbo Stream updates (plan status changes, note updates)
- Turbo Frame replacements (if used)
- Form submissions (Turbo-enabled forms)

#### Stimulus Controller Interactions
- **accordion_controller**: Expand/collapse sections
- **tabs_controller**: Tab switching, content updates
- **sidebar_controller**: Mobile menu toggle, keyboard navigation
- **note_edit_controller**: Inline editing, save/cancel
- **star_rating_controller**: Star selection, form submission
- **toast_controller**: Auto-dismiss, manual dismiss

#### Form Submissions & Validations
- Client-side validation feedback
- Server-side validation errors (display, field highlighting)
- Loading states (button disabled, spinners)
- Success states (redirects, flash messages)
- Error states (error messages, form re-render)

#### AJAX/Async Operations
- Loading indicators during API calls
- Error handling (network errors, server errors)
- Success feedback (toast notifications)
- Status polling (plan generation status)

#### Multi-step Processes
- Complete trip creation → note addition → plan generation → rating flow
- User registration → email confirmation → preferences setup flow

#### Cross-browser Compatibility
- Chrome/Chromium (primary)
- Firefox (if time permits)
- Safari (if time permits)

#### Responsive Design
- Mobile viewport (375px, 414px)
- Tablet viewport (768px, 1024px)
- Desktop viewport (1280px, 1920px)
- Sidebar behavior (mobile vs desktop)

#### Accessibility
- Keyboard navigation (Tab, Enter, Escape)
- Screen reader compatibility (ARIA labels, roles)
- Focus management (modal dialogs, form fields)
- Color contrast (if applicable)

#### State Persistence
- User session across page navigations
- Form data preservation on validation errors
- Flash messages persistence

#### Error Handling in UI
- Error message display (toast, inline)
- Flash message rendering
- 404 page display
- 500 error page display

---

### 7. Security Testing

**Test Files:**
- `spec/requests/security_spec.rb` ❌ (or integrate into existing request specs)

**Coverage Requirements:**

#### Authentication Bypass
- Unauthenticated access to protected routes (should redirect/401)
- Session hijacking attempts
- Token manipulation

#### Authorization Checks
- Users cannot access other users' trips (404, not 403)
- Users cannot modify other users' resources
- Parameter tampering (user_id override in params)
- Direct URL access to other users' resources

#### Input Validation
- SQL injection attempts (in search/filter parameters)
- XSS prevention (script tags in user input)
- Parameter tampering (malformed data, type coercion)
- File upload attacks (if applicable)

#### CSRF Protection
- CSRF token validation (for state-changing operations)
- Same-origin policy enforcement

#### Strong Parameters
- Mass assignment protection
- Unpermitted parameter filtering

**Test Pattern:**
```ruby
context 'authorization' do
  it 'prevents accessing other user\'s trip' do
    other_trip = create(:trip, user: other_user)
    sign_in user
    
    get trip_path(other_trip)
    expect(response).to have_http_status(:not_found)
  end
  
  it 'prevents user_id override in params' do
    sign_in user
    post trips_path, params: { trip: { name: 'Test', user_id: other_user.id } }
    
    created_trip = Trip.last
    expect(created_trip.user_id).to eq(user.id)
    expect(created_trip.user_id).not_to eq(other_user.id)
  end
end
```

---

### 8. Edge Cases & Error Scenarios

**Coverage Areas:**

#### Missing Required Data
- Nil values for required fields
- Empty strings for required fields
- Missing associations (trip without user, note without trip)

#### Invalid Data Formats
- Invalid date formats
- Invalid email formats
- Invalid enum values
- Invalid JSON in API responses

#### Boundary Conditions
- Empty arrays (no trips, no notes)
- Maximum length strings (10,000 char notes)
- Date boundaries (start_date = end_date, past dates)
- Number boundaries (0 people, negative numbers, very large numbers)

#### Database Constraints
- Unique constraint violations (duplicate emails)
- Foreign key violations (orphaned records)
- Check constraints (if any)

#### Concurrent Operations
- Simultaneous updates to same record
- Race conditions in plan generation
- Multiple users creating trips simultaneously

#### Large Datasets
- Pagination with many trips (100+)
- Performance with many notes per trip
- Performance with many generated plans

---

### 9. Test Organization & Best Practices

**Current Structure:**
```
spec/
  factories/          ✅
  lib/                ✅
  models/             ✅ (partial)
  requests/           ✅
  services/           ✅
  support/            ✅
  types/              ✅
```

**Missing Structure:**
```
spec/
  system/             ❌ (E2E tests)
  jobs/               ❌
  helpers/            ❌ (if needed)
  shared_examples/    ❌ (reusable test contexts)
```

**Best Practices:**

#### Use of `let`, `let!`, `before`, `after`
- Use `let` for lazy-loaded test data
- Use `let!` for data needed in `before` blocks
- Use `before` for setup, `after` for cleanup
- Avoid `let` for simple values (use `let(:user) { create(:user) }` not `let(:user_id) { 1 }`)

#### Shared Examples and Contexts
- Create shared examples for common patterns (authentication, authorization)
- Use contexts to group related tests
- Extract common setup to shared contexts

#### Test Helpers
- `spec/support/openrouter_helpers.rb` ✅ (exists)
- Add helpers for common authentication patterns
- Add helpers for Turbo Stream assertions
- Add helpers for Stimulus controller testing

#### Factory Definitions
- Use traits for variations (`:unconfirmed`, `:with_preferences`)
- Use sequences for unique values (emails)
- Use associations for related data
- Keep factories simple and focused

#### Test Data Isolation
- Use transactional fixtures (already enabled)
- Clean up between tests (automatic with transactions)
- For E2E tests, may need Database Cleaner if transactions don't work

---

## E2E Testing Setup Requirements

### Tool Selection

**Recommended: Capybara with Cuprite**
- **Cuprite**: Headless Chrome driver, faster than Selenium, no external browser needed
- **Alternative**: Capybara with Selenium (for real browser testing, slower but more realistic)
- **Alternative**: Playwright (if moving away from Capybara ecosystem)

**Justification:**
- Cuprite is faster and simpler than Selenium
- Works well with Rails asset pipeline
- Supports JavaScript execution
- Good for CI/CD (no browser installation needed)

### Driver Configuration

**Add to `spec/rails_helper.rb`:**
```ruby
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/cuprite'

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 1400],
    browser_options: {
      'no-sandbox' => nil,
      'disable-dev-shm-usage' => nil
    },
    headless: !ENV['HEADFUL'],
    js_errors: true
  )
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = 5
```

**Gemfile Addition:**
```ruby
group :development, :test do
  gem 'capybara', '~> 3.40'
  gem 'cuprite', '~> 0.15'
end
```

### Database Strategy for E2E Tests

- **Primary**: Use transactional fixtures (Rails default)
- **Fallback**: If transactions don't work with JavaScript, use Database Cleaner with truncation strategy
- **Configuration**: Keep `config.use_transactional_fixtures = true` for most tests, disable for system specs if needed

### JavaScript Execution

- Enable JavaScript in test environment (`config.environments/test.rb` already has asset pipeline)
- Ensure Turbo and Stimulus are loaded in test environment
- Test JavaScript errors don't break tests (use `js_errors: true` in driver config)

### Asset Compilation

- Ensure Tailwind CSS is compiled for test environment
- Ensure JavaScript assets are available
- Use `config.assets.compile = true` in test environment if needed

### Test Data Setup

- Use FactoryBot for E2E test data
- Create seed data helpers for complex scenarios
- Use `let!` for data needed before page load

### Screenshot and Video Capture

**Add to `spec/rails_helper.rb`:**
```ruby
RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    if example.exception
      take_screenshot
      take_screenshot(name: example.full_description.parameterize)
    end
  end
end
```

**Cuprite supports:**
- Screenshot capture on failures
- Video recording (with additional setup)

### Parallel Execution Considerations

- Use `parallel_tests` gem for parallel execution
- Ensure test database isolation
- Use unique test data (sequences, timestamps)
- Avoid shared state between parallel tests

---

## Test Quality Metrics

### Current Coverage Gaps

**Missing Test Files:**
- `spec/models/trip_spec.rb`
- `spec/models/note_spec.rb`
- `spec/models/generated_plan_spec.rb`
- `spec/models/user_preference_spec.rb`
- `spec/jobs/generated_plan_generation_job_spec.rb`
- `spec/services/trips_query_service_spec.rb`
- `spec/requests/profiles_spec.rb`
- `spec/requests/registrations_spec.rb`
- All `spec/system/*_spec.rb` files (E2E tests)

**Untested Code Paths:**
- Model custom validations edge cases
- Service error recovery paths
- Job retry logic
- Turbo Stream responses
- Stimulus controller error handling
- Accessibility features

### Test Refactoring Opportunities

- Extract shared examples for authentication/authorization
- Create page objects for E2E tests (if tests become complex)
- Consolidate WebMock stubbing patterns
- Extract common test data setup to factories/traits

### Slow Tests Optimization

- Use `:aggregate_failures` for related assertions
- Avoid unnecessary database queries (use `includes` in factories)
- Use `build` instead of `create` when possible
- Mock external API calls (already using WebMock)
- Use `let` instead of `let!` when data isn't needed immediately

### Test Organization Improvements

- Group related tests in shared contexts
- Use descriptive test names (should vs should not)
- Keep test files focused (one class per spec file)
- Use tags for test categorization (`:slow`, `:e2e`, `:integration`)

---

## CI/CD Integration

### Current CI Setup

**File:** `.github/workflows/ci.yml`
- ✅ Brakeman security scan
- ✅ Importmap audit
- ✅ Rubocop linting
- ❌ **Missing**: RSpec test execution

### Test Execution in CI

**Add to `.github/workflows/ci.yml`:**
```yaml
test:
  runs-on: ubuntu-latest
  services:
    postgres:
      image: postgres:16
      env:
        POSTGRES_PASSWORD: postgres
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: .ruby-version
        bundler-cache: true
    - name: Setup database
      env:
        RAILS_ENV: test
        DATABASE_URL: postgres://postgres:postgres@localhost:5432/travel_planner_test
      run: |
        bin/rails db:create
        bin/rails db:schema:load
    - name: Run tests
      env:
        RAILS_ENV: test
        DATABASE_URL: postgres://postgres:postgres@localhost:5432/travel_planner_test
      run: bundle exec rspec
```

### Test Database Setup

- Use `db:schema:load` instead of `db:migrate` (faster)
- Ensure test database is created before tests run
- Use PostgreSQL service in GitHub Actions

### Parallel Test Execution

- Use `parallel_tests` gem for parallel execution
- Split tests across multiple CI jobs (unit, integration, e2e)
- Use test result aggregation

### Test Reporting

- Add SimpleCov for coverage reporting
- Upload coverage reports to Codecov or similar
- Generate test result reports (JUnit XML for GitHub Actions)

### E2E Test Execution in CI

**Requirements:**
- Headless browser (Cuprite/Selenium headless)
- Chrome/Chromium installation in CI
- Increased timeout for E2E tests
- Retry strategy for flaky tests

**Configuration:**
```yaml
- name: Install Chrome dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y chromium-browser

- name: Run E2E tests
  env:
    HEADLESS: true
  run: bundle exec rspec spec/system
```

### E2E Test Stability

- Use explicit waits instead of `sleep`
- Use `Capybara.default_max_wait_time` for element waiting
- Retry flaky tests with `rspec-retry` gem
- Isolate E2E tests from unit tests (separate CI job)
- Use stable selectors (data-testid attributes)

---

## Documentation Requirements

### Test Setup Instructions

**File:** `spec/README.md`

**Contents:**
- How to run tests (`bundle exec rspec`)
- How to run specific test files
- How to run E2E tests
- How to run tests in parallel
- Environment setup (database, Chrome driver)

### Testing Patterns and Conventions

**Document:**
- Naming conventions (describe/context/it blocks)
- When to use `let` vs `let!` vs `before`
- How to test Turbo Stream responses
- How to test Stimulus controllers
- How to stub external APIs (WebMock patterns)

### Helper Methods Usage

**Document:**
- `OpenRouterHelpers` (WebMock stubbing)
- Devise test helpers (`sign_in`, `sign_out`)
- Custom helpers (if created)

### Common Test Scenarios

**Provide Examples:**
- Testing CRUD operations
- Testing authentication/authorization
- Testing form submissions
- Testing Turbo Stream updates
- Testing Stimulus controller interactions

### E2E Testing Guide

**File:** `spec/system/README.md`

**Contents:**
- How to write E2E tests
- Page object patterns (if used)
- Debugging tips (screenshots, console logs)
- Common pitfalls and solutions
- Best practices for stable tests

### Browser Testing Setup

**Instructions:**
- Installing Chrome/Chromium
- Installing Cuprite or Selenium drivers
- Configuring headless mode
- Troubleshooting driver issues

---

## Best Practices & Optimizations

### Making Tests Less Flaky

1. **Use Explicit Waits**
   - Prefer `have_content` over `sleep`
   - Use `Capybara.default_max_wait_time` appropriately
   - Wait for specific elements, not arbitrary time

2. **Stable Selectors**
   - Use `data-testid` attributes for E2E tests
   - Avoid CSS selectors that change with styling
   - Prefer semantic HTML selectors

3. **Isolate Test Data**
   - Use unique data per test (sequences, timestamps)
   - Avoid shared state between tests
   - Clean up test data properly

4. **Mock External Dependencies**
   - Always stub external APIs (WebMock)
   - Don't rely on external services in tests
   - Use consistent mock responses

5. **Avoid Timing Issues**
   - Use `travel_to` for time-dependent tests
   - Mock background jobs in unit tests
   - Use `perform_enqueued_jobs` for job testing

6. **Database Transactions**
   - Use transactional fixtures for speed
   - Disable transactions only when necessary (JavaScript tests)
   - Use Database Cleaner as fallback

### Performance Optimizations

1. **Test Data Creation**
   - Use `build` instead of `create` when possible
   - Use `build_stubbed` for read-only tests
   - Create data only when needed (`let` vs `let!`)

2. **Database Queries**
   - Use `includes` to avoid N+1 queries in tests
   - Test query counts with `expect { }.to make_database_queries(count: 2)`
   - Use `bulk_create` for large datasets

3. **Parallel Execution**
   - Run tests in parallel when possible
   - Split slow tests (E2E) into separate suite
   - Use test result caching

4. **Selective Test Execution**
   - Use tags to run specific test suites
   - Use `:focus` tag for debugging
   - Skip slow tests during development

5. **Asset Compilation**
   - Precompile assets for test environment
   - Use `config.assets.compile = false` in test (if possible)
   - Cache compiled assets

6. **Test Organization**
   - Group related tests together
   - Use shared contexts to reduce duplication
   - Keep test files focused and small

### Code Quality in Tests

1. **Descriptive Test Names**
   - Use clear, descriptive test descriptions
   - Follow pattern: "should [expected behavior] when [condition]"
   - Avoid vague descriptions

2. **DRY Principle**
   - Extract common setup to shared contexts
   - Use helper methods for repeated patterns
   - Use factories and traits for test data

3. **Single Responsibility**
   - One assertion per test (when possible)
   - Test one behavior at a time
   - Use `:aggregate_failures` for related assertions

4. **Maintainability**
   - Keep tests simple and readable
   - Avoid complex test logic
   - Document complex test scenarios

5. **Test Independence**
   - Tests should run in any order
   - Avoid test dependencies
   - Use `:order => :random` in RSpec config

### E2E Test Specific Optimizations

1. **Page Objects** (if tests become complex)
   - Encapsulate page interactions
   - Reduce duplication in E2E tests
   - Make tests more maintainable

2. **Test Data Management**
   - Use factories for E2E test data
   - Create realistic test scenarios
   - Avoid hardcoded test data

3. **Screenshot on Failure**
   - Automatically capture screenshots on failures
   - Save screenshots with descriptive names
   - Include screenshots in CI artifacts

4. **Retry Strategy**
   - Retry flaky E2E tests automatically
   - Use `rspec-retry` gem
   - Log retry attempts

5. **Test Isolation**
   - Each E2E test should be independent
   - Clean up between tests
   - Use unique test data

---

## Summary

This test plan covers:
- ✅ Current testing stack documentation
- ✅ Missing tools identification (Capybara, Cuprite, SimpleCov)
- ✅ Comprehensive test coverage areas (Models, Controllers, Services, Jobs, APIs, E2E, Security)
- ✅ E2E testing setup requirements (tool selection, configuration, database strategy)
- ✅ Test quality metrics and gaps
- ✅ CI/CD integration recommendations
- ✅ Documentation requirements
- ✅ Best practices and optimizations for flaky and performant tests

**Priority Actions:**
1. Add E2E testing tools (Capybara, Cuprite)
2. Create missing model specs (Trip, Note, GeneratedPlan, UserPreference)
3. Create E2E test suite (system specs)
4. Add test execution to CI pipeline
5. Add code coverage reporting (SimpleCov)
6. Create test documentation

