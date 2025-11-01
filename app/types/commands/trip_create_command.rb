# typed: strict
# frozen_string_literal: true

module Commands
  # Command Model for creating a new trip
  # Used by POST /trips endpoint
  # Derived from: trips table (subset of fields)
  class TripCreateCommand < T::Struct
    include BaseDTO
    extend T::Sig

    const :name, String
    const :destination, String
    const :start_date, String # ISO 8601 date format (YYYY-MM-DD)
    const :end_date, String # ISO 8601 date format (YYYY-MM-DD)
    const :number_of_people, Integer, default: 1

    sig { params(params: T::Hash[T.untyped, T.untyped]).returns(TripCreateCommand) }
    def self.from_params(params)
      trip_params = params[:trip] || params
      new(
        name: trip_params[:name].to_s,
        destination: trip_params[:destination].to_s,
        start_date: trip_params[:start_date].to_s,
        end_date: trip_params[:end_date].to_s,
        number_of_people: (trip_params[:number_of_people] || 1).to_i
      )
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_model_attributes
      {
        name:,
        destination:,
        start_date: Date.parse(start_date),
        end_date: Date.parse(end_date),
        number_of_people:
      }
    end
  end
end
