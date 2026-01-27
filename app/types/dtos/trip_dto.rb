# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for Trip resource
  # Represents trip data as returned by the API for list and show endpoints
  # Derived from: trips table
  class TripDTO < T::Struct
    extend T::Sig
    include BaseDTO

    # Core trip attributes from database
    const :id, Integer
    const :name, String
    const :destination, String
    const :start_date, String # ISO 8601 date format (YYYY-MM-DD)
    const :end_date, String # ISO 8601 date format (YYYY-MM-DD)
    const :number_of_people, Integer
    const :created_at, String # ISO 8601 datetime format
    const :updated_at, String # ISO 8601 datetime format

    # Optional association counts (included in list view)
    const :notes_count, T.nilable(Integer), default: nil
    const :generated_plans_count, T.nilable(Integer), default: nil

    # Optional nested associations (included in show view)
    # TODO: Temporarily commented out during DTO migration (Task 4)
    # Will be restored when Trip is migrated (Task 6)
    # const :notes, T.nilable(T::Array[DTOs::NoteDTO]), default: nil
    const :generated_plans, T.nilable(T::Array[DTOs::GeneratedPlanDTO]), default: nil

    sig { params(trip: Trip).returns(TripDTO) }
    def self.from_model(trip)
      new(
        id: trip.id,
        name: trip.name,
        destination: trip.destination,
        start_date: trip.start_date.to_s,
        end_date: trip.end_date.to_s,
        number_of_people: trip.number_of_people,
        created_at: trip.created_at.iso8601,
        updated_at: trip.updated_at.iso8601
      )
    end

    sig { params(trip: Trip, include_counts: T::Boolean).returns(TripDTO) }
    def self.from_model_with_counts(trip, include_counts: true)
      dto = from_model(trip)
      return dto unless include_counts

      new(
        id: dto.id,
        name: dto.name,
        destination: dto.destination,
        start_date: dto.start_date,
        end_date: dto.end_date,
        number_of_people: dto.number_of_people,
        created_at: dto.created_at,
        updated_at: dto.updated_at,
        notes_count: trip.notes.count,
        generated_plans_count: trip.generated_plans.count
      )
    end

    sig { params(trip: Trip).returns(TripDTO) }
    def self.from_model_with_associations(trip)
      # TODO: Temporarily disabled notes serialization during DTO migration (Task 4)
      # Will be restored when Trip is migrated (Task 6)
      new(
        id: trip.id,
        name: trip.name,
        destination: trip.destination,
        start_date: trip.start_date.to_s,
        end_date: trip.end_date.to_s,
        number_of_people: trip.number_of_people,
        created_at: trip.created_at.iso8601,
        updated_at: trip.updated_at.iso8601,
        # notes: trip.notes.map { |note| DTOs::NoteDTO.from_model(note) },
        generated_plans: trip.generated_plans.map { |plan| DTOs::GeneratedPlanDTO.from_model(plan) }
      )
    end
  end
end
