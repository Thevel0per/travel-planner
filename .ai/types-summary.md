# TravelPlanner Architecture Summary

### 1. Models (`app/models/`)

Standard ActiveRecord models with validations and associations:

| Model | Purpose | Key Features |
|-------|---------|--------------|
| `User` | User authentication | Devise integration, has preferences and trips |
| `Trip` | Travel trip | Date validation, belongs to user, has notes and plans |
| `Note` | Trip notes | Content validation, belongs to trip |
| `UserPreference` | Travel preferences | **Contains validation constants**, belongs to user |
| `GeneratedPlan` | AI-generated plans | **Rails native enum for status**, belongs to trip |

#### UserPreference Constants

Preference validation constants are defined directly in the model:

```ruby
class UserPreference < ApplicationRecord
  BUDGETS = %w[budget_conscious standard luxury].freeze
  ACCOMMODATIONS = %w[hotel airbnb hostel resort camping].freeze
  ACTIVITIES = %w[outdoors sightseeing cultural relaxation adventure nightlife shopping].freeze
  EATING_HABITS = %w[restaurants_only self_prepared mix].freeze
  
  validates :budget, inclusion: { in: BUDGETS, allow_nil: true }
  validates :accommodation, inclusion: { in: ACCOMMODATIONS, allow_nil: true }
  validates :eating_habits, inclusion: { in: EATING_HABITS, allow_nil: true }
end
```

#### GeneratedPlan Rails Enum

State machine pattern using Rails native enum:

```ruby
class GeneratedPlan < ApplicationRecord
  enum :status, {
    pending: 'pending',
    generating: 'generating',
    completed: 'completed',
    failed: 'failed'
  }, default: :pending
  
  # Provides:
  # - Query methods: pending?, generating?, completed?, failed?
  # - Bang methods: pending!, generating!, completed!, failed!
  # - Scopes: GeneratedPlan.pending, GeneratedPlan.completed, etc.
end
```

### 2. Serializers (`app/serializers/`)

JSON serialization using Blueprinter gem:

| Serializer | Purpose | Views |
|------------|---------|-------|
| `ApplicationSerializer` | Base serializer | - |
| `TripSerializer` | Trip responses | :list, :detail |
| `NoteSerializer` | Note responses | default |
| `UserPreferencesSerializer` | Preferences responses | default |
| `PreferenceOptionsSerializer` | Available options | default |
| `GeneratedPlanSerializer` | Plan list responses | default |
| `GeneratedPlanContentSerializer` | Plan detail content | default |
| `PaginationSerializer` | Pagination metadata | default |
| `ErrorSerializer` | Error responses | default |

**Key Features:**
- Clean DSL similar to Jbuilder
- Flexible field inclusion based on context
- Support for multiple views
- Type-safe through TypeSpec integration

### 3. Controllers (`app/controllers/`)

Standard Rails controllers using Strong Parameters:

| Controller | Responsibility |
|------------|----------------|
| `ApplicationController` | Base controller with pagination and error handling helpers |
| `TripsController` | CRUD for trips |
| `Trips::NotesController` | CRUD for trip notes |
| `Trips::GeneratedPlansController` | Generate and manage AI plans |
| `PreferencesController` | Update user preferences |
| `ProfileController` | User profile and preferences view |

**Strong Parameters Pattern:**

```ruby
class TripsController < ApplicationController
  def create
    @trip = current_user.trips.build(trip_params)
    
    if @trip.save
      render json: TripSerializer.render(@trip), status: :created
    else
      render json: ErrorSerializer.render_model_errors(@trip), status: :unprocessable_content
    end
  end
  
  private
  
  def trip_params
    params.require(:trip).permit(:name, :destination, :start_date, :end_date, :number_of_people)
  end
end
```

### 4. Services (`app/services/`)

Business logic extraction for complex operations:

| Service | Purpose |
|---------|---------|
| `GeneratedPlans::Generate` | Orchestrates AI plan generation |
| `TravelPlanGeneration::InputValidator` | Validates inputs before generation |
| `TravelPlanGeneration::PromptBuilder` | Builds AI prompts |
| `TravelPlanGeneration::SchemaBuilder` | Builds JSON schema for AI |
| `TravelPlanGeneration::PlanValidator` | Validates AI-generated plans |
| `ServiceResult` | Standard result object for services |

**Service Pattern:**

```ruby
class GeneratedPlans::Generate
  def initialize(trip_id:, user_id:, generated_plan_id: nil)
    @trip_id = trip_id
    @user_id = user_id
    @generated_plan_id = generated_plan_id
  end
  
  def call
    # Business logic here
    # Returns ServiceResult (success/failure with data/error_message)
  end
end
```

### 5. TypeSpec Definitions (`tsp/`)

API contract definitions using TypeSpec:

| File | Purpose |
|------|---------|
| `main.tsp` | Main entry point |
| `trips.tsp` | Trip-related models and operations |
| `notes.tsp` | Note-related models and operations |
| `preferences.tsp` | Preference models and operations |
| `generated_plans.tsp` | Generated plan models and operations |

**Benefits:**
- Single source of truth for API contracts
- Auto-generates OpenAPI/Swagger documentation
- Can generate TypeScript types for frontend
- Validates API responses match contracts

## Data Flow

### Creating a Resource

```
HTTP Request
    ↓
Controller receives params
    ↓
Strong Parameters validation (trip_params)
    ↓
Build model with params (trip = current_user.trips.build(trip_params))
    ↓
ActiveRecord validations
    ↓
Save to database
    ↓
Serialize with Blueprinter (TripSerializer.render(@trip))
    ↓
JSON Response
```

### Generating AI Plan

```
HTTP Request
    ↓
Controller calls service (GeneratedPlans::Generate.new(...).call)
    ↓
Service validates inputs (InputValidator)
    ↓
Service builds prompt (PromptBuilder)
    ↓
Service calls OpenRouter API
    ↓
Service validates response (PlanValidator)
    ↓
Service stores result in database (as JSON hash)
    ↓
Controller serializes (GeneratedPlanSerializer)
    ↓
JSON Response
```

## Key Files and Locations

### Models with Validation Constants
```
app/models/user_preference.rb         # BUDGETS, ACCOMMODATIONS, ACTIVITIES, EATING_HABITS
app/models/generated_plan.rb          # Rails enum :status
```

### Serializers
```
app/serializers/
├── application_serializer.rb          # Base class
├── trip_serializer.rb                 # Trip JSON
├── note_serializer.rb                 # Note JSON
├── user_preferences_serializer.rb     # Preferences JSON
├── preference_options_serializer.rb   # Available options JSON
├── generated_plan_serializer.rb       # Plan list JSON
├── generated_plan_content_serializer.rb # Plan detail JSON
├── pagination_serializer.rb           # Pagination metadata
└── error_serializer.rb                # Error responses
```

### Helpers
```
app/helpers/application_helper.rb      # Form options using UserPreference constants
```

### Services
```
app/services/generated_plans/
└── generate.rb                        # Main plan generation service

app/services/travel_plan_generation/
├── input_validator.rb                 # Input validation
├── prompt_builder.rb                  # AI prompt building
├── schema_builder.rb                  # JSON schema for AI
└── plan_validator.rb                  # AI response validation
```

## API Coverage

All endpoints implemented following Rails conventions:

### Trips
- ✅ GET /trips - List trips with pagination
- ✅ GET /trips/:id - Show trip with associations
- ✅ POST /trips - Create trip (Strong Parameters)
- ✅ PATCH /trips/:id - Update trip (Strong Parameters)
- ✅ DELETE /trips/:id - Delete trip

### Notes
- ✅ GET /trips/:trip_id/notes - List notes
- ✅ GET /trips/:trip_id/notes/:id - Show note
- ✅ POST /trips/:trip_id/notes - Create note
- ✅ PATCH /trips/:trip_id/notes/:id - Update note
- ✅ DELETE /trips/:trip_id/notes/:id - Delete note

### Generated Plans
- ✅ GET /trips/:trip_id/generated_plans - List plans
- ✅ GET /trips/:trip_id/generated_plans/:id - Show plan
- ✅ POST /trips/:trip_id/generated_plans - Generate plan
- ✅ PATCH /trips/:trip_id/generated_plans/:id - Update plan (rating)

### Preferences
- ✅ GET /preferences - Show preferences
- ✅ PUT /preferences - Update preferences
- ✅ GET /preferences/options - Get available options

## Testing Strategy

### Model Tests
- Test validations
- Test associations
- Test custom methods
- Test constants are frozen

### Controller Tests
- Test Strong Parameters
- Test authorization
- Test error handling
- Test pagination

### Serializer Tests
- Test field presence
- Test conditional fields
- Test associations
- Test views

### Service Tests
- Test business logic
- Test error cases
- Test retryability
- Test state transitions

### Integration Tests
- Test full request/response cycles
- Test authentication
- Test complex workflows

## Documentation Files

- `README.md` - Main project documentation
- `.ai/api-plan.md` - API specification
- `.ai/db-plan.md` - Database design
- `.ai/dto-refactoring-plan.md` - Refactoring plan (completed)
- `.ai/types-summary.md` - This file
- `app/serializers/README.md` - Serializer documentation
- `app/services/generated_plans/README.md` - Service documentation
- `tsp/README.md` - TypeSpec documentation