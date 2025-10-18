# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value('user@example.com').for(:email) }
    it { is_expected.to allow_value('test.user+tag@domain.co.uk').for(:email) }
    it { is_expected.not_to allow_value('invalid_email').for(:email) }
    it { is_expected.not_to allow_value('user@').for(:email) }
    it { is_expected.not_to allow_value('@example.com').for(:email) }
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a user with unique email' do
      user1 = create(:user)
      user2 = build(:user, email: user1.email)
      expect(user2).not_to be_valid
      expect(user2.errors[:email]).to include('has already been taken')
    end
  end

  describe 'password validation' do
    it 'requires password on creation' do
      user = build(:user, password: nil, password_confirmation: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'validates password confirmation' do
      user = build(:user, password: 'password123', password_confirmation: 'different')
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end

    it 'accepts valid password and confirmation' do
      user = build(:user, password: 'password123', password_confirmation: 'password123')
      expect(user).to be_valid
    end
  end

  describe 'email format validation' do
    valid_emails = [
      'user@example.com',
      'test.user@domain.co.uk',
      'user+tag@example.org',
      'firstname-lastname@example.com',
      'user123@example.com'
    ]

    invalid_emails = [
      'invalid_email',
      'user@',
      '@example.com',
      'user@.com',
      'user@example..com'
    ]

    valid_emails.each do |email|
      it "accepts #{email} as valid email" do
        user = build(:user, email:)
        expect(user).to be_valid
      end
    end

    invalid_emails.each do |email|
      it "rejects #{email} as invalid email" do
        user = build(:user, email:)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is invalid')
      end
    end
  end

  describe 'confirmation' do
    it 'can be unconfirmed' do
      user = build(:user, :unconfirmed)
      expect(user.confirmed?).to be false
    end

    it 'can confirm a user' do
      user = build(:user, :unconfirmed)
      user.confirm
      expect(user.confirmed?).to be true
    end
  end

  describe 'password recovery' do
    it 'can generate reset password token' do
      user = build(:user)
      user.reset_password_token = Devise.friendly_token
      user.reset_password_sent_at = Time.current
      expect(user.reset_password_token).to be_present
      expect(user.reset_password_sent_at).to be_present
    end
  end
end
