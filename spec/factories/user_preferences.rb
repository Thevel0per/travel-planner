# frozen_string_literal: true

FactoryBot.define do
  factory :user_preference do
    association :user

    budget { UserPreference::BUDGETS.sample }
    accommodation { UserPreference::ACCOMMODATIONS.sample }
    eating_habits { UserPreference::EATING_HABITS.sample }
    activities { UserPreference::ACTIVITIES.first(3).join(', ') }
  end
end
