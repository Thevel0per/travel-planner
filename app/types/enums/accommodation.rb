# typed: strict
# frozen_string_literal: true

module Enums
  # Accommodation preference options for travel planning
  class Accommodation < T::Enum
    extend T::Sig

    enums do
      Hotel = new('hotel')
      Airbnb = new('airbnb')
      Hostel = new('hostel')
      Resort = new('resort')
      Camping = new('camping')
    end

    sig { returns(T::Array[String]) }
    def self.string_values
      Accommodation.values.map(&:serialize)
    end
  end
end
