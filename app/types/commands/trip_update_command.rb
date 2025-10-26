# typed: strict
# frozen_string_literal: true

module Commands
  # Command Model for updating an existing trip
  # Used by PUT/PATCH /trips/:id endpoint
  # All fields are optional (partial updates allowed)
  # Derived from: trips table (subset of fields)
  class TripUpdateCommand < T::Struct
    include BaseDTO
    extend T::Sig

    const :name, T.nilable(String), default: nil
    const :destination, T.nilable(String), default: nil
    const :start_date, T.nilable(String), default: nil # ISO 8601 date format (YYYY-MM-DD)
    const :end_date, T.nilable(String), default: nil # ISO 8601 date format (YYYY-MM-DD)
    const :number_of_people, T.nilable(Integer), default: nil

    sig { params(params: T::Hash[T.untyped, T.untyped]).returns(TripUpdateCommand) }
    def self.from_params(params)
      trip_params = params[:trip] || params
      new(
        name: trip_params[:name],
        destination: trip_params[:destination],
        start_date: trip_params[:start_date],
        end_date: trip_params[:end_date],
        number_of_people: trip_params[:number_of_people]
      )
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_model_attributes
      attributes = {}
      attributes[:name] = name if name
      attributes[:destination] = destination if destination
      attributes[:start_date] = Date.parse(start_date) if start_date
      attributes[:end_date] = Date.parse(end_date) if end_date
      attributes[:number_of_people] = number_of_people if number_of_people
      attributes
    end
  end
end
