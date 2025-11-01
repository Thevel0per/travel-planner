# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe OpenRouter::Client do
  let(:api_key) { 'test-api-key' }
  let(:client) { described_class.new(api_key:) }
  let(:messages) { [ { 'role' => 'user', 'content' => 'Hello' } ] }
  let(:schema) do
    {
      'type' => 'object',
      'properties' => {
        'response' => { 'type' => 'string' }
      }
    }
  end

  before do
    # Enable support directory loading
    require Rails.root.join('spec/support/openrouter_helpers')
  end

  describe '#initialize' do
    it 'initializes with provided api_key' do
      expect(client.api_key).to eq(api_key)
    end

    it 'uses default configuration values' do
      expect(client.timeout).to eq(60)
      expect(client.max_retries).to eq(3)
    end

    it 'raises ConfigurationError when api_key is missing' do
      allow(OpenRouter.configuration).to receive(:api_key).and_return(nil)
      expect { described_class.new }.to raise_error(OpenRouter::ConfigurationError)
    end
  end

  describe '#chat_completion_with_schema' do
    context 'when request is successful' do
      let(:response_content) { { 'response' => 'Hello back!' }.to_json }

      before do
        stub_openrouter_success(content: response_content)
      end

      it 'returns a successful response' do
        response = client.chat_completion_with_schema(
          messages:,
          schema:
        )

        expect(response).to be_success
        expect(response.content).to eq(response_content)
      end

      it 'includes usage information' do
        response = client.chat_completion_with_schema(
          messages:,
          schema:
        )

        expect(response.usage).to be_present
        expect(response.total_tokens).to eq(100)
      end
    end

    context 'when authentication fails' do
      before do
        stub_openrouter_error(status: 401, message: 'Invalid API key')
      end

      it 'returns a failure response with AuthenticationError' do
        response = client.chat_completion_with_schema(
          messages:,
          schema:
        )

        expect(response).to be_failure
        expect(response.error).to be_a(OpenRouter::AuthenticationError)
      end
    end

    context 'when rate limit is exceeded' do
      before do
        stub_openrouter_rate_limit(retry_after: 2)
      end

      it 'retries the request' do
        # First call hits rate limit, subsequent calls should succeed
        stub_sequence = stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            { status: 429, headers: { 'Retry-After' => '1' } },
            { status: 200, body: { choices: [ { message: { content: '{}' } } ], usage: {} }.to_json }
          )

        response = client.chat_completion_with_schema(
          messages:,
          schema:
        )

        expect(response).to be_success
        expect(stub_sequence).to have_been_requested.times(2)
      end
    end

    context 'when server error occurs' do
      before do
        stub_openrouter_error(status: 500, message: 'Internal server error')
      end

      it 'retries the request' do
        stub_sequence = stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            { status: 500 },
            { status: 500 },
            { status: 500 },
            { status: 200, body: { choices: [ { message: { content: '{}' } } ], usage: {} }.to_json }
          )

        response = client.chat_completion_with_schema(
          messages:,
          schema:
        )

        expect(response).to be_success
        expect(stub_sequence).to have_been_requested.times(4)
      end
    end

    context 'when all retries are exhausted' do
      before do
        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(status: 500).times(4)
      end

      it 'returns a failure response' do
        response = client.chat_completion_with_schema(
          messages:,
          schema:
        )

        expect(response).to be_failure
        expect(response.error).to be_a(OpenRouter::ServerError)
      end
    end

    context 'when request times out' do
      before do
        stub_openrouter_timeout
      end

      it 'retries the request' do
        stub_sequence = stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_timeout
          .times(1)
          .then
          .to_return(status: 200, body: { choices: [ { message: { content: '{}' } } ], usage: {} }.to_json)

        response = client.chat_completion_with_schema(
          messages:,
          schema:
        )

        expect(response).to be_success
      end
    end
  end

  describe '#test_connection' do
    context 'when connection is successful' do
      before do
        stub_openrouter_success(content: '{"response": "ok"}')
      end

      it 'returns true' do
        expect(client.test_connection).to be true
      end
    end

    context 'when connection fails' do
      before do
        stub_openrouter_error(status: 401)
      end

      it 'returns false' do
        expect(client.test_connection).to be false
      end
    end
  end
end
