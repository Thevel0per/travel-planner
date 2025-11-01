# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceResult do
  describe '.success' do
    it 'creates successful result' do
      result = described_class.success(data: { foo: 'bar' })
      expect(result).to be_success
      expect(result).not_to be_failure
    end

    it 'includes data' do
      result = described_class.success(data: { foo: 'bar' })
      expect(result.data).to eq({ foo: 'bar' })
    end

    it 'has no error' do
      result = described_class.success
      expect(result.error_message).to be_nil
    end

    it 'is not retryable' do
      result = described_class.success
      expect(result).not_to be_retryable
    end
  end

  describe '.failure' do
    it 'creates failed result' do
      result = described_class.failure(error_message: 'Test error')
      expect(result).to be_failure
      expect(result).not_to be_success
    end

    it 'includes error message' do
      result = described_class.failure(error_message: 'Test error')
      expect(result.error_message).to eq('Test error')
    end

    it 'has no data' do
      result = described_class.failure(error_message: 'Test error')
      expect(result.data).to be_nil
    end

    it 'respects retryable flag' do
      result = described_class.failure(error_message: 'Test error', retryable: true)
      expect(result).to be_retryable
    end

    it 'defaults to not retryable' do
      result = described_class.failure(error_message: 'Test error')
      expect(result).not_to be_retryable
    end
  end
end

