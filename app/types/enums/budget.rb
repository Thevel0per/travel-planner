# typed: strict
# frozen_string_literal: true

module Enums
  # Budget preference options for travel planning
  class Budget < T::Enum
    extend T::Sig

    enums do
      BudgetConscious = new('budget_conscious')
      Standard = new('standard')
      Luxury = new('luxury')
    end

    sig { returns(T::Array[String]) }
    def self.string_values
      Budget.values.map(&:serialize)
    end
  end
end
