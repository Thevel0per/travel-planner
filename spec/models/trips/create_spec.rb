# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trips::Create do
  let(:user) { create(:user) }
  let(:command) do
    Commands::TripCreateCommand.new(
      name: 'Summer Vacation',
      destination: 'Paris, France',
      start_date: '2025-07-15',
      end_date: '2025-07-22',
      number_of_people: 2
    )
  end
  let(:service) { described_class.new(user:, command:) }

  describe '#call' do
    context 'with valid command' do
      it 'creates a new trip' do
        expect { service.call }.to change(Trip, :count).by(1)
      end

      it 'returns a persisted trip' do
        trip = service.call
        expect(trip).to be_persisted
        expect(trip.persisted?).to be true
      end

      it 'associates trip with the user' do
        trip = service.call
        expect(trip.user).to eq(user)
      end

      it 'sets trip attributes correctly' do
        trip = service.call
        expect(trip.name).to eq('Summer Vacation')
        expect(trip.destination).to eq('Paris, France')
        expect(trip.start_date).to eq(Date.new(2025, 7, 15))
        expect(trip.end_date).to eq(Date.new(2025, 7, 22))
        expect(trip.number_of_people).to eq(2)
      end

      it 'sets user_id from user parameter, not command' do
        other_user = create(:user)
        command_with_user_id = Commands::TripCreateCommand.new(
          name: 'Test',
          destination: 'Test',
          start_date: '2025-01-01',
          end_date: '2025-01-05',
          number_of_people: 1
        )
        service = described_class.new(user:, command: command_with_user_id)

        trip = service.call
        expect(trip.user_id).to eq(user.id)
        expect(trip.user_id).not_to eq(other_user.id)
      end
    end

    context 'with validation errors' do
      let(:invalid_command) do
        Commands::TripCreateCommand.new(
          name: '',
          destination: '',
          start_date: '2025-07-15',
          end_date: '2025-07-22',
          number_of_people: 0
        )
      end
      let(:service) { described_class.new(user:, command: invalid_command) }

      it 'returns an unsaved trip with errors' do
        trip = service.call
        expect(trip).not_to be_persisted
        expect(trip.errors).to be_present
      end

      it 'includes validation errors' do
        trip = service.call
        expect(trip.errors[:name]).to include("can't be blank")
        expect(trip.errors[:destination]).to include("can't be blank")
        expect(trip.errors[:number_of_people]).to be_present
      end
    end

    context 'with invalid date format' do
      let(:invalid_date_command) do
        Commands::TripCreateCommand.new(
          name: 'Test',
          destination: 'Test',
          start_date: 'invalid-date',
          end_date: 'also-invalid',
          number_of_people: 1
        )
      end
      let(:service) { described_class.new(user:, command: invalid_date_command) }

      it 'raises Date::Error' do
        expect { service.call }.to raise_error(Date::Error)
      end
    end

    context 'with date range validation error' do
      let(:invalid_range_command) do
        Commands::TripCreateCommand.new(
          name: 'Test',
          destination: 'Test',
          start_date: '2025-07-22',
          end_date: '2025-07-15',
          number_of_people: 1
        )
      end
      let(:service) { described_class.new(user:, command: invalid_range_command) }

      it 'returns trip with validation error' do
        trip = service.call
        expect(trip).not_to be_persisted
        expect(trip.errors[:end_date]).to include('must be after start date')
      end
    end
  end
end
