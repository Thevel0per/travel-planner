# Serializers

This directory contains Blueprinter serializers for JSON API responses.

## Structure

```
app/serializers/
├── application_serializer.rb  # Base serializer (placeholder for shared behavior)
├── error_serializer.rb        # Error response serialization
├── pagination_serializer.rb   # Pagination metadata serialization
└── [resource]_serializer.rb   # Individual resource serializers
```

## Usage

### Basic Serializer

```ruby
class TripSerializer < ApplicationSerializer
  identifier :id
  
  fields :name, :destination, :start_date, :end_date
  
  # Custom field with block
  field :created_at do |trip|
    trip.created_at.iso8601
  end
end

# In controller
render json: TripSerializer.render(@trip)
```

### Error Serializer

```ruby
# Single error message
render json: ErrorSerializer.render_error('Not found'), status: :not_found

# Model validation errors
if @trip.save
  render json: TripSerializer.render(@trip)
else
  render json: ErrorSerializer.render_model_errors(@trip), status: :unprocessable_entity
end

# Custom errors
render json: ErrorSerializer.render_errors({ name: ['is required'] })
```

### Pagination Serializer

```ruby
# With Pagy
@pagy, @trips = pagy(Trip.all)

render json: {
  trips: TripSerializer.render(@trips),
  meta: PaginationSerializer.from_pagy(@pagy)
}
```

### Conditional Fields

```ruby
class TripSerializer < ApplicationSerializer
  identifier :id
  fields :name, :destination
  
  # Conditional field
  field :notes_count, if: ->(_, trip, options) { options[:include_counts] }
  
  # Association
  association :notes, blueprint: NoteSerializer, if: ->(_, _, options) { 
    options[:include_associations] 
  }
end

# Usage
TripSerializer.render(@trip, include_counts: true)
TripSerializer.render(@trip, include_associations: true)
```

## Configuration

Global Blueprinter configuration is in `config/initializers/blueprinter.rb`.

## Resources

- [Blueprinter Documentation](https://github.com/procore/blueprinter)
- [Rails API Design Guide](https://guides.rubyonrails.org/api_app.html)
