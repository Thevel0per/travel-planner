# frozen_string_literal: true

FactoryBot.define do
  factory :trip do
    association :user
    name { 'Summer Vacation' }
    destination { 'Paris, France' }
    start_date { Date.today + 30.days }
    end_date { Date.today + 37.days }
    number_of_people { 2 }

    trait :past do
      start_date { Date.today - 10.days }
      end_date { Date.today - 3.days }
    end

    trait :future do
      start_date { Date.today + 60.days }
      end_date { Date.today + 67.days }
    end
  end
end
