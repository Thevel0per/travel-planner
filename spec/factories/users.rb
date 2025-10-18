# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_token { Devise.friendly_token }
      confirmation_sent_at { Time.current }
    end

    trait :with_reset_password do
      reset_password_token { Devise.friendly_token }
      reset_password_sent_at { Time.current }
    end

    trait :with_confirmation_token do
      confirmation_token { Devise.friendly_token }
      confirmation_sent_at { Time.current }
    end
  end
end
