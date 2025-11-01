# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenRouter::Error do
  describe 'error hierarchy' do
    it 'all errors inherit from base Error class' do
      expect(OpenRouter::AuthenticationError.new).to be_a(OpenRouter::Error)
      expect(OpenRouter::RateLimitError.new).to be_a(OpenRouter::Error)
      expect(OpenRouter::ServerError.new).to be_a(OpenRouter::Error)
      expect(OpenRouter::TimeoutError.new).to be_a(OpenRouter::Error)
      expect(OpenRouter::NetworkError.new).to be_a(OpenRouter::Error)
      expect(OpenRouter::ResponseParsingError.new).to be_a(OpenRouter::Error)
      expect(OpenRouter::ClientError.new).to be_a(OpenRouter::Error)
      expect(OpenRouter::ConfigurationError.new).to be_a(OpenRouter::Error)
    end
  end

  describe OpenRouter::AuthenticationError do
    it 'is not retryable' do
      error = described_class.new
      expect(error.retryable?).to be false
    end

    it 'has default message' do
      error = described_class.new
      expect(error.message).to eq('Invalid API key')
    end
  end

  describe OpenRouter::RateLimitError do
    it 'is retryable' do
      error = described_class.new
      expect(error.retryable?).to be true
    end

    it 'can store retry_after value' do
      error = described_class.new(retry_after: 60)
      expect(error.retry_after).to eq(60)
    end
  end

  describe OpenRouter::ServerError do
    it 'is retryable' do
      error = described_class.new
      expect(error.retryable?).to be true
    end

    it 'can store status_code' do
      error = described_class.new(status_code: 500)
      expect(error.status_code).to eq(500)
    end
  end

  describe OpenRouter::TimeoutError do
    it 'is retryable' do
      error = described_class.new
      expect(error.retryable?).to be true
    end
  end

  describe OpenRouter::NetworkError do
    it 'is retryable' do
      error = described_class.new
      expect(error.retryable?).to be true
    end
  end

  describe OpenRouter::ResponseParsingError do
    it 'is not retryable' do
      error = described_class.new
      expect(error.retryable?).to be false
    end
  end

  describe OpenRouter::ClientError do
    it 'is not retryable' do
      error = described_class.new
      expect(error.retryable?).to be false
    end

    it 'requires status_code' do
      error = described_class.new(status_code: 400)
      expect(error.status_code).to eq(400)
    end
  end

  describe OpenRouter::ConfigurationError do
    it 'is not retryable' do
      error = described_class.new
      expect(error.retryable?).to be false
    end
  end
end

