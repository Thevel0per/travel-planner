# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenRouter::Response do
  describe '.success' do
    let(:content) { '{"message": "Hello"}' }
    let(:usage) { { 'total_tokens' => 100, 'prompt_tokens' => 50, 'completion_tokens' => 50 } }
    let(:raw_response) { { 'id' => '123' } }

    subject(:response) do
      described_class.success(
        content:,
        usage:,
        raw_response:
      )
    end

    it 'creates a successful response' do
      expect(response).to be_success
      expect(response).not_to be_failure
    end

    it 'includes content' do
      expect(response.content).to eq(content)
    end

    it 'includes usage information' do
      expect(response.usage).to eq(usage)
      expect(response.total_tokens).to eq(100)
      expect(response.prompt_tokens).to eq(50)
      expect(response.completion_tokens).to eq(50)
    end

    it 'includes raw response' do
      expect(response.raw_response).to eq(raw_response)
    end

    it 'has no error' do
      expect(response.error).to be_nil
    end
  end

  describe '.failure' do
    let(:error) { OpenRouter::AuthenticationError.new('Invalid API key') }

    subject(:response) { described_class.failure(error:) }

    it 'creates a failed response' do
      expect(response).to be_failure
      expect(response).not_to be_success
    end

    it 'includes error' do
      expect(response.error).to eq(error)
    end

    it 'has no content' do
      expect(response.content).to be_nil
    end
  end

  describe '#content_as_json' do
    context 'when content is valid JSON' do
      let(:json_content) { { message: 'Hello' }.to_json }
      let(:response) do
        described_class.success(
          content: json_content,
          usage: {},
          raw_response: {}
        )
      end

      it 'parses and returns JSON' do
        expect(response.content_as_json).to eq({ 'message' => 'Hello' })
      end
    end

    context 'when content is nil' do
      let(:response) { described_class.failure(error: OpenRouter::Error.new) }

      it 'returns nil' do
        expect(response.content_as_json).to be_nil
      end
    end

    context 'when content is invalid JSON' do
      let(:response) do
        described_class.success(
          content: 'not json',
          usage: {},
          raw_response: {}
        )
      end

      it 'raises ResponseParsingError' do
        expect { response.content_as_json }.to raise_error(OpenRouter::ResponseParsingError)
      end
    end
  end

  describe '#retryable?' do
    context 'with retryable error' do
      let(:error) { OpenRouter::ServerError.new }
      let(:response) { described_class.failure(error:) }

      it 'returns true' do
        expect(error.retryable?).to be true
      end
    end

    context 'with non-retryable error' do
      let(:error) { OpenRouter::AuthenticationError.new }
      let(:response) { described_class.failure(error:) }

      it 'returns false' do
        expect(error.retryable?).to be false
      end
    end
  end
end
