# typed: strict
# frozen_string_literal: true

module Enums
  # Status values for AI-generated travel plans
  class GeneratedPlanStatus < T::Enum
    extend T::Sig

    enums do
      Pending = new('pending')
      Generating = new('generating')
      Completed = new('completed')
      Failed = new('failed')
    end

    sig { returns(T::Array[String]) }
    def self.string_values
      GeneratedPlanStatus.values.map(&:serialize)
    end
  end
end
