# frozen_string_literal: true

FactoryBot.define do
  factory :note do
    association :trip
    content { 'This is a sample note about the trip.' }

    trait :long do
      content { 'A' * 500 }
    end

    trait :short do
      content { 'Quick note' }
    end
  end
end
