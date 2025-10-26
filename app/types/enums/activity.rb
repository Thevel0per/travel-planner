# typed: strict
# frozen_string_literal: true

module Enums
  # Activity preference options for travel planning
  class Activity < T::Enum
    extend T::Sig

    enums do
      Outdoors = new('outdoors')
      Sightseeing = new('sightseeing')
      Cultural = new('cultural')
      Relaxation = new('relaxation')
      Adventure = new('adventure')
      Nightlife = new('nightlife')
      Shopping = new('shopping')
    end

    sig { returns(T::Array[String]) }
    def self.string_values
      Activity.values.map(&:serialize)
    end
  end
end
