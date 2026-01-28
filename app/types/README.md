# TravelPlanner Type System

This directory contains type-safe enumeration definitions for the TravelPlanner application.

## Overview

The type system now follows Rails best practices with clear separation of concerns:

- **Enums**: Type-safe enumeration types for constrained string values (located here)
- **Serializers**: JSON serialization using Blueprinter (see `app/serializers/`)
- **Strong Parameters**: Input validation using Rails conventions (in controllers)
- **Model Validations**: Data validation in ActiveRecord models (see `app/models/`)
- **TypeSpec**: API contract definitions and OpenAPI schema generation (see `tsp/`)

## Structure

```
app/types/
└── enums/                      # Type-safe enumeration types
    ├── budget.rb               # Budget preference options
    ├── accommodation.rb        # Accommodation type options
    ├── activity.rb             # Activity preference options
    ├── eating_habit.rb         # Eating habit options
    └── generated_plan_status.rb # Plan generation status options
```

## Usage

### Using Enums

Enums provide type-safe access to predefined values. They use Sorbet's `T::Enum` for compile-time type checking:

```ruby
# Get all valid budget options
budget_options = Enums::Budget.values
# => ["budget_conscious", "standard", "luxury"]

# Create enum instance
budget = Enums::Budget::Standard
budget.serialize # => "standard"

# Use in model validations
class UserPreference < ApplicationRecord
  validates :budget, inclusion: { in: Enums::Budget.values }, allow_nil: true
  validates :accommodation, inclusion: { in: Enums::Accommodation.values }, allow_nil: true
end
```

### Using Serializers (Blueprinter)

For JSON serialization, use Blueprinter serializers in `app/serializers/`:

```ruby
class TripsController < ApplicationController
  def show
    @trip = current_user.trips.includes(:notes, :generated_plans).find(params[:id])
    render json: TripSerializer.render(@trip, view: :detail)
  end

  def index
    @trips = current_user.trips.page(params[:page])
    render json: TripSerializer.render(@trips, view: :list)
  end
end
```

### Input Validation (Strong Parameters)

Use Rails Strong Parameters for input validation:

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

### Error Handling

Use ErrorSerializer for consistent error responses:

```ruby
# Single error message
render json: ErrorSerializer.render_error("Trip not found"), status: :not_found

# Validation errors from model
render json: ErrorSerializer.render_model_errors(@trip), status: :unprocessable_content

# Custom error hash
render json: ErrorSerializer.render_errors({ base: ["Something went wrong"] }), status: :bad_request
```

## Type Definitions

### Available Enums

Type-safe enumerations for constrained string values:

**`Enums::Budget`** - Budget preferences
- Values: `"budget_conscious"`, `"standard"`, `"luxury"`
- Used in: `UserPreference` model

**`Enums::Accommodation`** - Accommodation types
- Values: `"hotel"`, `"airbnb"`, `"hostel"`, `"resort"`, `"camping"`
- Used in: `UserPreference` model

**`Enums::Activity`** - Activity preferences
- Values: `"outdoors"`, `"sightseeing"`, `"cultural"`, `"food_tours"`, `"adventure"`, `"relaxation"`, `"nightlife"`, `"shopping"`
- Used in: `UserPreference` model

**`Enums::EatingHabit`** - Eating preferences
- Values: `"restaurants_only"`, `"self_prepared"`, `"mix"`
- Used in: `UserPreference` model

**`Enums::GeneratedPlanStatus`** - Plan generation status
- Values: `"pending"`, `"generating"`, `"completed"`, `"failed"`
- Used in: `GeneratedPlan` model

## Architecture Overview

The application follows Rails best practices with clear separation of concerns:

1. **Models** (`app/models/`) - Business logic, validations, associations
2. **Controllers** (`app/controllers/`) - Request handling, Strong Parameters
3. **Serializers** (`app/serializers/`) - JSON response formatting with Blueprinter
4. **Enums** (`app/types/enums/`) - Type-safe value constraints with Sorbet
5. **Services** (`app/services/`) - Complex business operations
6. **TypeSpec** (`tsp/`) - API contract definitions and OpenAPI generation

## Connection to Database Models

Enums are used in model validations to ensure data integrity:

| Enum | Used In | Database Field |
|------|---------|----------------|
| `Enums::Budget` | `UserPreference` | `budget` |
| `Enums::Accommodation` | `UserPreference` | `accommodation` |
| `Enums::Activity` | `UserPreference` | `activities` |
| `Enums::EatingHabit` | `UserPreference` | `eating_habits` |
| `Enums::GeneratedPlanStatus` | `GeneratedPlan` | `status` |

Models use these enums in validations to ensure only valid values are stored in the database.

## Sorbet Type Checking

Enums in this directory use Sorbet's `T::Enum` for compile-time type checking. Key features:

- `T::Enum` - Type-safe enumerations with compile-time validation
- `sig` - Method signatures for type safety
- `extend T::Sig` - Enable signature syntax

To run Sorbet type checking:

```bash
bundle exec srb tc
```

## Best Practices

1. **Enum Usage**: Always use enum constants instead of raw strings when possible
2. **Model Validation**: Use enums in model validations to ensure data integrity
3. **Type Safety**: Leverage Sorbet signatures for compile-time type checking
4. **Serializers**: Use Blueprinter serializers for JSON responses (not DTOs)
5. **Strong Parameters**: Use Rails Strong Parameters for input validation (not Command objects)
6. **Error Handling**: Use ErrorSerializer for consistent error responses

## Complete Controller Example (Rails Best Practices)

```ruby
class Trips::NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_note, only: [:show, :update, :destroy]

  def index
    pagy, notes = pagy(@trip.notes.ordered)
    render_paginated_json(notes, serializer_class: NoteSerializer, pagy: pagy, key: :notes)
  end

  def show
    render_model_json(@note, serializer_class: NoteSerializer)
  end

  def create
    @note = @trip.notes.build(note_params)
    
    if @note.save
      render_model_json(@note, serializer_class: NoteSerializer, status: :created)
    else
      render json: ErrorSerializer.render_model_errors(@note), status: :unprocessable_content
    end
  end

  def update
    if @note.update(note_params)
      render_model_json(@note, serializer_class: NoteSerializer)
    else
      render json: ErrorSerializer.render_model_errors(@note), status: :unprocessable_content
    end
  end

  def destroy
    @note.destroy
    head :no_content
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  def set_note
    @note = @trip.notes.find(params[:id])
  end

  # Rails Strong Parameters (standard Rails pattern)
  def note_params
    params.require(:note).permit(:content)
  end
end
```

## Related Documentation

- **Models**: `app/models/` - Business logic and validations
- **Serializers**: `app/serializers/` - JSON response formatting
- **TypeSpec API Definitions**: `tsp/` - API contracts and OpenAPI schema
- **Database Schema**: `db/schema.rb`
- **Sorbet Documentation**: https://sorbet.org/
- **Blueprinter Documentation**: https://github.com/procore/blueprinter
- **Rails Guides**: https://guides.rubyonrails.org/
