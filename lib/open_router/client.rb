# typed: strict
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module OpenRouter
  # Generic HTTP client for OpenRouter API
  class Client
    extend T::Sig

    DEFAULT_MODEL = 'perplexity/sonar-pro-search'  # :online enables web search capabilities

    sig { returns(String) }
    attr_reader :api_key

    sig { returns(Integer) }
    attr_reader :timeout

    sig { returns(Integer) }
    attr_reader :max_retries

    sig do
      params(
        api_key: T.nilable(String),
        timeout: T.nilable(Integer),
        max_retries: T.nilable(Integer)
      ).void
    end
    def initialize(api_key: nil, timeout: nil, max_retries: nil)
      # Ensure configuration is loaded if it hasn't been yet
      if OpenRouter.configuration.api_key.nil? || OpenRouter.configuration.api_key.empty?
        if defined?(Rails) && Rails.application
          api_key_value = Rails.application.credentials.dig(:openrouter, :api_key) || ENV['OPENROUTER_API_KEY']
          OpenRouter.configuration.api_key = api_key_value if api_key_value
        end
      end

      @api_key = T.let(api_key || OpenRouter.configuration.api_key || '', String)
      @timeout = T.let(timeout || OpenRouter.configuration.timeout, Integer)
      @max_retries = T.let(max_retries || OpenRouter.configuration.max_retries, Integer)

      raise ConfigurationError, 'API key is required' if @api_key.empty?
    end

    sig do
      params(
        messages: T::Array[T::Hash[String, String]],
        schema: T::Hash[String, T.untyped],
        model: String,
        temperature: Float,
        max_tokens: Integer
      ).returns(Response)
    end
    def chat_completion_with_schema(
      messages:,
      schema:,
      model: DEFAULT_MODEL,
      temperature: 0.7,
      max_tokens: 32000  # Increased for Perplexity and complex plans with web search results
    )
      payload = build_request_payload(
        model:,
        messages:,
        schema:,
        temperature:,
        max_tokens:
      )

      execute_request_with_retry(payload)
    end

    sig { returns(T::Boolean) }
    def test_connection
      begin
        response = chat_completion_with_schema(
          messages: [ { 'role' => 'user', 'content' => 'Hello' } ],
          schema: { 'type' => 'object', 'properties' => { 'response' => { 'type' => 'string' } } }
        )
        response.success?
      rescue Error
        false
      end
    end

    private

    sig do
      params(
        model: String,
        messages: T::Array[T::Hash[String, String]],
        schema: T::Hash[String, T.untyped],
        temperature: Float,
        max_tokens: Integer
      ).returns(T::Hash[String, T.untyped])
    end
    def build_request_payload(model:, messages:, schema:, temperature:, max_tokens:)
      payload = {
        model:,
        messages:,
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'response_schema',
            strict: true,
            schema:
          }
        },
        temperature:,
        max_tokens:
      }

      # Enable web search if model doesn't already have :online suffix
      # Note: Perplexity models have built-in search, so we don't need the web plugin
      # For other models, add web plugin to enable real-time web search for Google Maps URLs
      unless model.end_with?(':online') || model.include?('perplexity')
        payload[:plugins] = [ { id: 'web', max_results: 5 } ]
      end

      payload
    end

    sig { params(payload: T::Hash[String, T.untyped]).returns(Response) }
    def execute_request_with_retry(payload)
      attempt = 0
      last_error = T.let(nil, T.nilable(Error))

      while attempt <= @max_retries
        begin
          return execute_request(payload)
        rescue RateLimitError => e
          last_error = e
          wait_time = e.retry_after || exponential_backoff(attempt)
          log_retry(attempt, e, wait_time)
          sleep(wait_time)
          attempt += 1
        rescue ServerError, TimeoutError, NetworkError => e
          last_error = e
          if attempt < @max_retries
            wait_time = exponential_backoff(attempt)
            log_retry(attempt, e, wait_time)
            sleep(wait_time)
            attempt += 1
          else
            break
          end
        rescue Error => e
          # Non-retryable errors
          return Response.failure(error: e)
        end
      end

      # All retries exhausted
      Response.failure(error: last_error || ServerError.new('Unknown error'))
    end

    sig { params(payload: T::Hash[String, T.untyped]).returns(Response) }
    def execute_request(payload)
      uri = URI.parse(OpenRouter.configuration.api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = @timeout
      http.open_timeout = @timeout

      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{@api_key}"
      request.body = payload.to_json

      response = http.request(request)
      parse_response(response)
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      raise TimeoutError, "Request timeout: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED => e
      raise NetworkError, "Network error: #{e.message}"
    rescue Error
      # Re-raise OpenRouter errors as-is
      raise
    rescue StandardError => e
      raise NetworkError, "Unexpected error: #{e.message}"
    end

    sig { params(response: Net::HTTPResponse).returns(Response) }
    def parse_response(response)
      case response.code.to_i
      when 200..299
        parse_success_response(response)
      when 401
        raise AuthenticationError, 'Invalid API key'
      when 429
        retry_after = response['Retry-After']&.to_i
        raise RateLimitError.new('Rate limit exceeded', retry_after:)
      when 400
        # Log the error response body for debugging
        begin
          error_body = JSON.parse(response.body)
          error_message = error_body['error'] || error_body['message'] || response.message
          Rails.logger.error("OpenRouter Bad Request response: #{error_body.inspect}") if defined?(Rails)
          raise ClientError.new("Client error: #{error_message}", status_code: 400)
        rescue JSON::ParserError
          raise ClientError.new("Client error: #{response.message}", status_code: 400)
        end
      when 500..599
        raise ServerError.new("Server error: #{response.message}", status_code: response.code.to_i)
      else
        raise ClientError.new("Client error: #{response.message}", status_code: response.code.to_i)
      end
    end

    sig { params(response: Net::HTTPResponse).returns(Response) }
    def parse_success_response(response)
      response_body_str = response.body.to_s
      body = JSON.parse(response_body_str)
      content = body.dig('choices', 0, 'message', 'content')
      usage = body['usage']

      raise ResponseParsingError, 'Missing content in response' if content.nil?

      Response.success(
        content:,
        usage: usage || {},
        raw_response: body
      )
    rescue JSON::ParserError => e
      # Log the response body for debugging truncated responses
      response_body_preview = response_body_str&.first(1000) || response.body.to_s&.first(1000) || 'No response body'
      Rails.logger.error("JSON parse error: #{e.message}") if defined?(Rails)
      Rails.logger.error("Response body preview (first 1000 chars): #{response_body_preview}") if defined?(Rails)
      Rails.logger.error("Response body length: #{response_body_str&.length || response.body.to_s&.length || 'unknown'}") if defined?(Rails)
      raise ResponseParsingError, "Failed to parse response: #{e.message}"
    end

    sig { params(attempt: Integer).returns(Integer) }
    def exponential_backoff(attempt)
      [ 2**attempt, 32 ].min
    end

    sig { params(attempt: Integer, error: Error, wait_time: Integer).void }
    def log_retry(attempt, error, wait_time)
      logger = OpenRouter.configuration.logger
      return unless logger

      logger.warn(
        "OpenRouter request failed (attempt #{attempt + 1}/#{@max_retries + 1}): " \
        "#{error.class.name} - #{error.message}. Retrying in #{wait_time}s..."
      )
    end
  end
end
