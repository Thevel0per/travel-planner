# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Commands::TripCreateCommand do
  describe '.from_params' do
    context 'with nested parameters (trip key)' do
      let(:params) do
        {
          trip: {
            name: 'Summer Vacation',
            destination: 'Paris, France',
            start_date: '2025-07-15',
            end_date: '2025-07-22',
            number_of_people: 2
          }
        }
      end

      it 'extracts parameters from trip key' do
        command = described_class.from_params(params)

        expect(command.name).to eq('Summer Vacation')
        expect(command.destination).to eq('Paris, France')
        expect(command.start_date).to eq('2025-07-15')
        expect(command.end_date).to eq('2025-07-22')
        expect(command.number_of_people).to eq(2)
      end
    end

    context 'with flat parameters (no trip key)' do
      let(:params) do
        {
          name: 'Tokyo Adventure',
          destination: 'Tokyo, Japan',
          start_date: '2025-08-01',
          end_date: '2025-08-10',
          number_of_people: 3
        }
      end

      it 'extracts parameters directly from params' do
        command = described_class.from_params(params)

        expect(command.name).to eq('Tokyo Adventure')
        expect(command.destination).to eq('Tokyo, Japan')
        expect(command.start_date).to eq('2025-08-01')
        expect(command.end_date).to eq('2025-08-10')
        expect(command.number_of_people).to eq(3)
      end
    end

    context 'with number_of_people parameter handling' do
      it 'converts string to integer' do
        params = {
          trip: {
            name: 'Test Trip',
            destination: 'Test',
            start_date: '2025-01-01',
            end_date: '2025-01-05',
            number_of_people: '5'
          }
        }

        command = described_class.from_params(params)
        expect(command.number_of_people).to eq(5)
      end

      it 'converts nil to 1 (which will fail validation)' do
        params = {
          trip: {
            name: 'Test Trip',
            destination: 'Test',
            start_date: '2025-01-01',
            end_date: '2025-01-05',
            number_of_people: nil
          }
        }

        command = described_class.from_params(params)
        expect(command.number_of_people).to eq(1)
      end

      it 'accepts integer directly' do
        params = {
          trip: {
            name: 'Test Trip',
            destination: 'Test',
            start_date: '2025-01-01',
            end_date: '2025-01-05',
            number_of_people: 4
          }
        }

        command = described_class.from_params(params)
        expect(command.number_of_people).to eq(4)
      end
    end
  end

  describe '#to_model_attributes' do
    let(:command) do
      described_class.new(
        name: 'Summer Vacation',
        destination: 'Paris, France',
        start_date: '2025-07-15',
        end_date: '2025-07-22',
        number_of_people: 2
      )
    end

    it 'converts dates from ISO 8601 strings to Date objects' do
      attributes = command.to_model_attributes

      expect(attributes[:start_date]).to be_a(Date)
      expect(attributes[:start_date]).to eq(Date.new(2025, 7, 15))
      expect(attributes[:end_date]).to be_a(Date)
      expect(attributes[:end_date]).to eq(Date.new(2025, 7, 22))
    end

    it 'includes all trip attributes' do
      attributes = command.to_model_attributes

      expect(attributes[:name]).to eq('Summer Vacation')
      expect(attributes[:destination]).to eq('Paris, France')
      expect(attributes[:number_of_people]).to eq(2)
      expect(attributes[:start_date]).to be_a(Date)
      expect(attributes[:end_date]).to be_a(Date)
    end

    it 'raises error for invalid date format' do
      invalid_command = described_class.new(
        name: 'Test',
        destination: 'Test',
        start_date: 'invalid-date',
        end_date: '2025-07-22',
        number_of_people: 1
      )

      expect { invalid_command.to_model_attributes }.to raise_error(Date::Error)
    end
  end
end
