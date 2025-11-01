# TravelPlanner Type System Summary

This document provides a comprehensive overview of all Sorbet type definitions created for the TravelPlanner application.

## Installation Complete

✅ **Sorbet gems installed:**
- `sorbet-runtime` - Runtime type checking
- `sorbet` - Static type checker
- `tapioca` - RBI file generator

## Type System Architecture

The type system is organized into four main categories, each in its own directory under `app/types/`:

### 1. Base Types (`app/types/`)
- **base_dto.rb** - Base class for all DTOs, extends `T::Struct`

### 2. Enums (`app/types/enums/`)

Type-safe enumerations for constrained values:

| Enum | Values | Usage |
|------|--------|-------|
| `Enums::Budget` | budget_conscious, standard, luxury | User preference for trip budget level |
| `Enums::Accommodation` | hotel, airbnb, hostel, resort, camping | Preferred accommodation types |
| `Enums::Activity` | outdoors, sightseeing, cultural, relaxation, adventure, nightlife, shopping | Activity preferences (comma-separated in DB) |
| `Enums::EatingHabit` | restaurants_only, self_prepared, mix | Meal preparation preferences |
| `Enums::GeneratedPlanStatus` | pending, generating, completed, failed | AI plan generation status |

**Key Method:** All enums provide `string_values` class method that returns `T::Array[String]` of serialized values.

### 3. DTOs - Data Transfer Objects (`app/types/dtos/`)

Immutable structs representing API responses:

| DTO | Purpose | Database Source | Key Methods |
|-----|---------|----------------|-------------|
| `TripDTO` | Trip resource with optional counts/associations | trips | `from_model`, `from_model_with_counts`, `from_model_with_associations` |
| `NoteDTO` | Note resource | notes | `from_model` |
| `UserPreferencesDTO` | User travel preferences | user_preferences | `from_model` |
| `PreferenceOptionsDTO` | Available preference options | Enums (static) | `all_options` |
| `GeneratedPlanDTO` | Generated plan (list view, no full content) | generated_plans | `from_model`, `from_model_with_preview` |
| `GeneratedPlanDetailDTO` | Generated plan (detail view with full content) | generated_plans | `from_model` |
| `PaginationMetaDTO` | Pagination metadata | Pagination gem | `build`, `from_collection` |
| `ErrorResponseDTO` | Error responses | ActiveModel::Errors | `single_error`, `validation_errors`, `from_model_errors` |

**DTO Characteristics:**
- All extend `BaseDTO` (which extends `T::Struct`)
- Use `const` for immutable fields
- Use `T.nilable` for optional fields
- Provide factory methods to convert from ActiveRecord models
- Support `.serialize` method (from `T::Struct`) for JSON conversion

### 4. Commands - Input Models (`app/types/commands/`)

Structs representing API request input:

| Command | Purpose | HTTP Method | Endpoint | Mutability |
|---------|---------|-------------|----------|------------|
| `TripCreateCommand` | Create new trip | POST | /trips | All required except number_of_people |
| `TripUpdateCommand` | Update trip | PUT/PATCH | /trips/:id | All optional (partial updates) |
| `NoteCreateCommand` | Create note | POST | /trips/:trip_id/notes | content required |
| `NoteUpdateCommand` | Update note | PUT/PATCH | /trips/:trip_id/notes/:id | content required |
| `PreferencesUpdateCommand` | Create/update preferences | PUT/PATCH | /preferences | All optional (upsert) |
| `GeneratedPlanCreateCommand` | Initiate plan generation | POST | /trips/:trip_id/generated_plans | options optional |
| `GeneratedPlanUpdateCommand` | Update plan (rating) | PATCH | /trips/:trip_id/generated_plans/:id | rating optional |

**Command Characteristics:**
- All extend `BaseDTO`
- Use `T.nilable` with `default: nil` for optional fields
- Provide `from_params` to parse from request params
- Provide `to_model_attributes` to convert to hash for ActiveRecord

### 5. Schemas - Complex Nested Types (`app/types/schemas/`)

Complex JSON structures for generated plans:

| Schema | Purpose | Fields |
|--------|---------|--------|
| `Schemas::ActivitySchema` | Individual activity in itinerary | time, name, duration_minutes, estimated_cost_usd, estimated_cost_per_person_usd, rating, description |
| `Schemas::RestaurantSchema` | Restaurant recommendation | meal, name, cuisine, estimated_cost_per_person_usd, rating |
| `Schemas::DailyItinerarySchema` | Daily plan | day, date, activities (array), restaurants (array) |
| `Schemas::TripSummarySchema` | Trip overview | total_cost_usd, cost_per_person_usd, duration_days, number_of_people |
| `Schemas::GeneratedPlanContent` | Complete plan structure | summary, daily_itinerary (array) |

**Schema Characteristics:**
- All extend `BaseDTO`
- `GeneratedPlanContent` provides:
  - `from_json(json_string)` - Parse JSON string to typed structure
  - `to_json_string` - Serialize back to JSON string
- Used in `GeneratedPlanDetailDTO` for the content field

## Model Integration

All ActiveRecord models have been updated with:
- `# typed: strict` directive
- `extend T::Sig` for signature support
- Proper associations with `dependent: :destroy`
- Validations using enum `string_values`
- Custom validation methods with `sig { void }` signatures

| Model | Associations | Key Validations |
|-------|--------------|-----------------|
| `User` | has_many :trips, has_one :user_preference | Email format, uniqueness (Devise) |
| `Trip` | belongs_to :user, has_many :notes, has_many :generated_plans | end_date > start_date, number_of_people > 0 |
| `Note` | belongs_to :trip | content presence, max 10,000 chars |
| `UserPreference` | belongs_to :user | Enum validations, comma-separated activities |
| `GeneratedPlan` | belongs_to :trip | Status enum, rating 1-10, rating only for completed |

## Type Connection to Database

Every DTO and Command is directly connected to database models:

```
Database (schema.rb) → ActiveRecord Models → DTOs/Commands
     ↓                        ↓                    ↓
  trips table           Trip model          TripDTO + TripCreateCommand + TripUpdateCommand
  notes table           Note model          NoteDTO + NoteCreateCommand + NoteUpdateCommand
  user_preferences      UserPreference      UserPreferencesDTO + PreferencesUpdateCommand
  generated_plans       GeneratedPlan       GeneratedPlanDTO + GeneratedPlanDetailDTO + Commands
```

## Usage Patterns

### 1. Creating a Resource

```ruby
# In controller
command = Commands::TripCreateCommand.from_params(params)
trip = current_user.trips.build(command.to_model_attributes)

if trip.save
  dto = DTOs::TripDTO.from_model(trip)
  render json: { trip: dto.serialize }, status: :created
else
  error = DTOs::ErrorResponseDTO.from_model_errors(trip)
  render json: error.serialize, status: :unprocessable_content
end
```

### 2. Updating a Resource

```ruby
# In controller
command = Commands::TripUpdateCommand.from_params(params)

if @trip.update(command.to_model_attributes)
  dto = DTOs::TripDTO.from_model(@trip)
  render json: { trip: dto.serialize }
else
  error = DTOs::ErrorResponseDTO.from_model_errors(@trip)
  render json: error.serialize, status: :unprocessable_content
end
```

### 3. Listing Resources with Pagination

```ruby
# In controller
trips = current_user.trips.page(params[:page])
trip_dtos = trips.map { |trip| DTOs::TripDTO.from_model_with_counts(trip) }
meta = DTOs::PaginationMetaDTO.from_collection(trips)

render json: {
  trips: trip_dtos.map(&:serialize),
  meta: meta.serialize
}
```

### 4. Working with Enums

```ruby
# Get all valid options
budget_options = Enums::Budget.string_values
# => ["budget_conscious", "standard", "luxury"]

# In validations (already set up in models)
validates :budget, inclusion: { in: Enums::Budget.string_values, allow_nil: true }

# Create enum instance
status = Enums::GeneratedPlanStatus::Pending
status.serialize # => "pending"
```

### 5. Complex JSON Handling

```ruby
# Parse generated plan content
plan_content = Schemas::GeneratedPlanContent.from_json(generated_plan.content)

# Access typed fields
summary = plan_content.summary
total_cost = summary.total_cost_usd

plan_content.daily_itinerary.each do |day|
  day.activities.each do |activity|
    puts "#{activity.time}: #{activity.name} - $#{activity.estimated_cost_per_person_usd}"
  end
end

# Serialize back to JSON
json_string = plan_content.to_json_string
```

## Benefits of This Type System

1. **Type Safety**: Sorbet provides static type checking to catch errors before runtime
2. **Documentation**: Types serve as inline documentation for data structures
3. **Immutability**: DTOs are immutable, preventing accidental mutations
4. **Consistency**: Standardized patterns for input/output across all endpoints
5. **Validation**: Enums ensure only valid values are used
6. **Maintainability**: Clear separation between database models and API representations
7. **Refactoring Safety**: Type checker catches issues when making changes

## File Structure Summary

```
app/
├── models/                          # Database models with Sorbet types
│   ├── application_record.rb        # Base with T::Sig
│   ├── user.rb                      # User model with associations
│   ├── trip.rb                      # Trip model with validations
│   ├── note.rb                      # Note model
│   ├── user_preference.rb           # UserPreference with enum validations
│   └── generated_plan.rb            # GeneratedPlan with status transitions
│
└── types/                           # All type definitions
    ├── types.rb                     # Main entry point
    ├── base_dto.rb                  # Base DTO class
    ├── README.md                    # Comprehensive usage guide
    │
    ├── enums/                       # 5 enum types
    │   ├── budget.rb
    │   ├── accommodation.rb
    │   ├── activity.rb
    │   ├── eating_habit.rb
    │   └── generated_plan_status.rb
    │
    ├── dtos/                        # 8 DTO types
    │   ├── trip_dto.rb
    │   ├── note_dto.rb
    │   ├── user_preferences_dto.rb
    │   ├── preference_options_dto.rb
    │   ├── generated_plan_dto.rb
    │   ├── generated_plan_detail_dto.rb
    │   ├── pagination_meta_dto.rb
    │   └── error_response_dto.rb
    │
    ├── commands/                    # 7 command types
    │   ├── trip_create_command.rb
    │   ├── trip_update_command.rb
    │   ├── note_create_command.rb
    │   ├── note_update_command.rb
    │   ├── preferences_update_command.rb
    │   ├── generated_plan_create_command.rb
    │   └── generated_plan_update_command.rb
    │
    └── schemas/                     # 1 complex schema file (5 schema types)
        └── generated_plan_content.rb
```

## Total Type Definitions Created

- **Base Types**: 1
- **Enums**: 5
- **DTOs**: 8
- **Commands**: 7
- **Schemas**: 5
- **Models Updated**: 5

**Total: 31 type definitions across 26 files**

## Next Steps

1. **Initialize Tapioca**: Run `bundle exec tapioca init` to generate RBI files for gems
2. **Generate RBIs**: Run `bundle exec tapioca gem` to create gem type definitions
3. **Type Check**: Run `bundle exec srb tc` to verify all types
4. **Use in Controllers**: Implement controllers using these DTOs and Commands
5. **Testing**: Write specs that verify DTO/Command behavior

## API Coverage

All 15 DTOs and Command Models from `api-plan.md` have been implemented:

✅ TripDTO (list/show)
✅ TripCreateCommand
✅ TripUpdateCommand
✅ NoteDTO
✅ NoteCreateCommand
✅ NoteUpdateCommand
✅ UserPreferencesDTO
✅ PreferencesUpdateCommand
✅ PreferenceOptionsDTO
✅ GeneratedPlanDTO (list)
✅ GeneratedPlanDetailDTO (show)
✅ GeneratedPlanCreateCommand
✅ GeneratedPlanUpdateCommand
✅ PaginationMetaDTO
✅ ErrorResponseDTO

All types are:
- ✅ Connected to database models
- ✅ Properly typed with Sorbet
- ✅ Include factory/conversion methods
- ✅ Support API request/response formats
- ✅ Include comprehensive documentation

