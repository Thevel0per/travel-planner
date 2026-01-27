# typed: strict
# frozen_string_literal: true

module Trips
  # Service object for creating new trips
  # Encapsulates trip creation logic including validation and error handling
  class Create
    extend T::Sig

    sig { returns(User) }
    attr_reader :user

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :attributes

    sig { params(user: User, attributes: T::Hash[Symbol, T.untyped]).void }
    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes
    end

    # Creates a new trip for the user
    # Returns the trip instance (saved on success, unsaved with errors on failure)
    # Check trip.persisted? or trip.errors.any? to determine success/failure
    sig { returns(Trip) }
    def call
      # Build trip instance from attributes
      trip = user.trips.new(attributes)

      # Attempt to save (triggers model validations)
      trip.save
      trip
    end
  end
end
