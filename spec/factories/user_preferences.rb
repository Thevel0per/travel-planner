# frozen_string_literal: true

FactoryBot.define do
  factory :user_preference do
    association :user

    budget { Enums::Budget.string_values.sample }
    accommodation { Enums::Accommodation.string_values.sample }
    eating_habits { Enums::EatingHabit.string_values.sample }
    activities { Enums::Activity.string_values.first(3).join(', ') }
  end
end
