# TravelPlanner Type System

This directory contains all Sorbet type definitions for the TravelPlanner application, providing type safety for DTOs (Data Transfer Objects), Command Models, and related structures.

## Overview

The type system is organized into several categories:

- **DTOs**: Immutable data structures representing API responses
- **Commands**: Input structures for API requests (create/update operations)
- **Enums**: Enumeration types for constrained string values
- **Schemas**: Complex nested structures (e.g., generated plan content)

## Structure

```
app/types/
├── types.rb                    # Main entry point - require this file to load all types
├── base_dto.rb                 # Base class for all DTOs
├── enums/                      # Enumeration types
│   ├── budget.rb
│   ├── accommodation.rb
│   ├── activity.rb
│   ├── eating_habit.rb
│   └── generated_plan_status.rb
├── dtos/                       # Data Transfer Objects (API responses)
│   ├── trip_dto.rb
│   ├── note_dto.rb
│   ├── user_preferences_dto.rb
│   ├── preference_options_dto.rb
│   ├── generated_plan_dto.rb
│   ├── generated_plan_detail_dto.rb
│   ├── pagination_meta_dto.rb
│   └── error_response_dto.rb
├── commands/                   # Command Models (API requests)
│   ├── trip_create_command.rb
│   ├── trip_update_command.rb
│   ├── note_create_command.rb
│   ├── note_update_command.rb
│   ├── preferences_update_command.rb
│   ├── generated_plan_create_command.rb
│   └── generated_plan_update_command.rb
└── schemas/                    # Complex nested structures
    └── generated_plan_content.rb
```

## Usage

### Loading Types

To use types in your code, require the main types file:

```ruby
require_relative 'app/types/types'
```

### Using DTOs in Controllers

DTOs are used to serialize model data for API responses:

```ruby
class TripsController < ApplicationController
  def show
    trip = current_user.trips.find(params[:id])
    trip_dto = DTOs::TripDTO.from_model_with_associations(trip)
    
    render json: { trip: trip_dto.serialize }
  end

  def index
    trips = current_user.trips.page(params[:page])
    trip_dtos = trips.map { |trip| DTOs::TripDTO.from_model_with_counts(trip) }
    meta = DTOs::PaginationMetaDTO.from_collection(trips)
    
    render json: {
      trips: trip_dtos.map(&:serialize),
      meta: meta.serialize
    }
  end
end
```

### Using Commands in Controllers

Commands are used to parse and validate input data:

```ruby
class TripsController < ApplicationController
  def create
    command = Commands::TripCreateCommand.from_params(params)
    trip = current_user.trips.build(command.to_model_attributes)
    
    if trip.save
      trip_dto = DTOs::TripDTO.from_model(trip)
      render json: { trip: trip_dto.serialize }, status: :created
    else
      error_dto = DTOs::ErrorResponseDTO.from_model_errors(trip)
      render json: error_dto.serialize, status: :unprocessable_content
    end
  end
end
```

### Using Enums

Enums provide type-safe access to predefined values:

```ruby
# Get all valid budget options
budget_options = Enums::Budget.values
# => ["budget_conscious", "standard", "luxury"]

# Create enum instance
budget = Enums::Budget::Standard
budget.serialize # => "standard"

# Use in validations (models already set up with this)
validates :budget, inclusion: { in: Enums::Budget.values }
```

### Error Handling

Use ErrorResponseDTO for consistent error responses:

```ruby
# Single error message
error = DTOs::ErrorResponseDTO.single_error("Trip not found")
render json: error.serialize, status: :not_found

# Validation errors from model
error = DTOs::ErrorResponseDTO.from_model_errors(trip)
render json: error.serialize, status: :unprocessable_content
```

## Type Definitions

### DTOs (Data Transfer Objects)

DTOs are immutable structs that represent data returned by the API. Each DTO:
- Extends `BaseDTO` (which extends `T::Struct`)
- Uses `const` for immutable fields
- Provides `from_model` class methods to convert from ActiveRecord models
- Fields match API response structure defined in `api-plan.md`

**Available DTOs:**
- `TripDTO` - Trip resource with optional counts and associations
- `NoteDTO` - Note resource
- `UserPreferencesDTO` - User preferences
- `PreferenceOptionsDTO` - Available preference options
- `GeneratedPlanDTO` - Generated plan (list view, no full content)
- `GeneratedPlanDetailDTO` - Generated plan (detail view with full content)
- `PaginationMetaDTO` - Pagination metadata
- `ErrorResponseDTO` - Error responses

### Commands (Input Models)

Commands are structs that represent input data for create/update operations. Each command:
- Extends `BaseDTO`
- Uses `const` with `T.nilable` for optional fields
- Provides `from_params` to parse from request parameters
- Provides `to_model_attributes` to convert to hash for ActiveRecord

**Available Commands:**
- `TripCreateCommand` - Create new trip
- `TripUpdateCommand` - Update existing trip (partial updates)
- `NoteCreateCommand` - Create new note
- `NoteUpdateCommand` - Update existing note
- `PreferencesUpdateCommand` - Create/update preferences (partial updates)
- `GeneratedPlanCreateCommand` - Initiate plan generation
- `GeneratedPlanUpdateCommand` - Update plan (mainly for rating)

### Enums

Type-safe enumerations for constrained string values:

- `Enums::Budget` - Budget preferences (budget_conscious, standard, luxury)
- `Enums::Accommodation` - Accommodation types (hotel, airbnb, hostel, resort, camping)
- `Enums::Activity` - Activity preferences (outdoors, sightseeing, cultural, etc.)
- `Enums::EatingHabit` - Eating preferences (restaurants_only, self_prepared, mix)
- `Enums::GeneratedPlanStatus` - Plan generation status (pending, generating, completed, failed)

### Schemas

Complex nested structures for structured data:

- `Schemas::GeneratedPlanContent` - Full structure of AI-generated plan
- `Schemas::TripSummarySchema` - Trip summary with costs and duration
- `Schemas::DailyItinerarySchema` - Daily plan with activities and restaurants
- `Schemas::ActivitySchema` - Individual activity details
- `Schemas::RestaurantSchema` - Restaurant recommendation

## Connection to Database Models

All DTOs and Commands are directly derived from database models defined in `db/schema.rb`:

| DTO/Command | Database Table | Model |
|-------------|----------------|-------|
| TripDTO, TripCreateCommand, TripUpdateCommand | trips | Trip |
| NoteDTO, NoteCreateCommand, NoteUpdateCommand | notes | Note |
| UserPreferencesDTO, PreferencesUpdateCommand | user_preferences | UserPreference |
| GeneratedPlanDTO, GeneratedPlanDetailDTO, GeneratedPlanCreateCommand, GeneratedPlanUpdateCommand | generated_plans | GeneratedPlan |

Models include Sorbet type signatures and use the enum values for validation.

## Sorbet Type Checking

This codebase uses Sorbet for static type checking. Key Sorbet features used:

- `T::Struct` - Immutable data structures
- `T::Enum` - Type-safe enumerations
- `const` - Immutable fields
- `T.nilable` - Optional fields
- `T::Array`, `T::Hash` - Collection types
- `sig` - Method signatures
- `extend T::Sig` - Enable signature syntax

To run type checking:

```bash
bundle exec srb tc
```

## Best Practices

1. **Immutability**: DTOs are immutable. To modify, create a new instance.
2. **Validation**: Validate at the model level, not in DTOs/Commands.
3. **Serialization**: Use `.serialize` method (provided by T::Struct) to convert to hash for JSON.
4. **Type Safety**: Always use enum types instead of raw strings when possible.
5. **Conversion Methods**: Use provided `from_model` and `to_model_attributes` methods.
6. **Error Handling**: Always use ErrorResponseDTO for consistent error responses.

## Examples

### Complete CRUD Controller Example

```ruby
class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_note, only: [:show, :update, :destroy]

  def index
    notes = @trip.notes.ordered.page(params[:page])
    note_dtos = notes.map { |note| DTOs::NoteDTO.from_model(note) }
    meta = DTOs::PaginationMetaDTO.from_collection(notes)
    
    render json: { notes: note_dtos.map(&:serialize), meta: meta.serialize }
  end

  def show
    note_dto = DTOs::NoteDTO.from_model(@note)
    render json: { note: note_dto.serialize }
  end

  def create
    command = Commands::NoteCreateCommand.from_params(params)
    note = @trip.notes.build(command.to_model_attributes)
    
    if note.save
      note_dto = DTOs::NoteDTO.from_model(note)
      render json: { note: note_dto.serialize }, status: :created
    else
      error_dto = DTOs::ErrorResponseDTO.from_model_errors(note)
      render json: error_dto.serialize, status: :unprocessable_content
    end
  end

  def update
    command = Commands::NoteUpdateCommand.from_params(params)
    
    if @note.update(command.to_model_attributes)
      note_dto = DTOs::NoteDTO.from_model(@note)
      render json: { note: note_dto.serialize }
    else
      error_dto = DTOs::ErrorResponseDTO.from_model_errors(@note)
      render json: error_dto.serialize, status: :unprocessable_content
    end
  end

  def destroy
    @note.destroy
    render json: { message: 'Note deleted successfully' }
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    error = DTOs::ErrorResponseDTO.single_error('Trip not found')
    render json: error.serialize, status: :not_found
  end

  def set_note
    @note = @trip.notes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    error = DTOs::ErrorResponseDTO.single_error('Note not found')
    render json: error.serialize, status: :not_found
  end
end
```

## Related Documentation

- Database Schema: `db/schema.rb` and `.ai/db-plan.md`
- API Specification: `.ai/api-plan.md`
- Sorbet Documentation: https://sorbet.org/
- Ruby on Rails Guides: https://guides.rubyonrails.org/

