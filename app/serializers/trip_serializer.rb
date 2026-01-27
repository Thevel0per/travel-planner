# frozen_string_literal: true

# Serializer for Trip resources
# Implements TypeSpec Trip models from tsp/trips.tsp
# Supports multiple views: basic, with_counts (list), with_associations (detail)
class TripSerializer < ApplicationSerializer
  identifier :id

  fields :name, :destination, :number_of_people

  # Format dates as ISO 8601 date strings (YYYY-MM-DD)
  field :start_date do |trip|
    trip.start_date.to_s
  end

  field :end_date do |trip|
    trip.end_date.to_s
  end

  # Format timestamps as ISO 8601
  field :created_at do |trip|
    trip.created_at.iso8601
  end

  field :updated_at do |trip|
    trip.updated_at.iso8601
  end

  # Conditional fields for list view (with counts)
  field :notes_count, if: ->(_, _, options) { options[:include_counts] } do |trip|
    trip.notes.size
  end

  field :generated_plans_count, if: ->(_, _, options) { options[:include_counts] } do |trip|
    trip.generated_plans.size
  end

  # Associations for detail view
  association :notes, blueprint: NoteSerializer, if: ->(_, _, options) { 
    options[:include_associations] 
  }

  association :generated_plans, blueprint: GeneratedPlanSerializer, if: ->(_, _, options) { 
    options[:include_associations] 
  }
end
