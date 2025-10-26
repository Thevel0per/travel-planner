# typed: strict
# frozen_string_literal: true

module Enums
  # Eating habit preference options for travel planning
  class EatingHabit < T::Enum
    extend T::Sig

    enums do
      RestaurantsOnly = new('restaurants_only')
      SelfPrepared = new('self_prepared')
      Mix = new('mix')
    end

    sig { returns(T::Array[String]) }
    def self.string_values
      EatingHabit.values.map(&:serialize)
    end
  end
end
