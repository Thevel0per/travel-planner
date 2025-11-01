# typed: strict
# frozen_string_literal: true

module Trips
  # Service object for creating new trips
  # Encapsulates trip creation logic including validation and error handling
  class Create
    extend T::Sig

    sig { returns(User) }
    attr_reader :user

    sig { returns(Commands::TripCreateCommand) }
    attr_reader :command

    sig { params(user: User, command: Commands::TripCreateCommand).void }
    def initialize(user:, command:)
      @user = user
      @command = command
    end

    # Creates a new trip for the user
    # Returns the trip instance (saved on success, unsaved with errors on failure)
    # Check trip.persisted? or trip.errors.any? to determine success/failure
    sig { returns(Trip) }
    def call
      # Convert command to model attributes (dates are parsed from strings)
      model_attributes = command.to_model_attributes

      # Set user_id from authenticated session (security: prevent user spoofing)
      model_attributes[:user_id] = user.id

      # Build trip instance from attributes
      trip = user.trips.new(model_attributes)

      # Attempt to save (triggers model validations)
      trip.save
      trip
    end
  end
end
