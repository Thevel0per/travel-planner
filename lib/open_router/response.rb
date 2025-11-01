# typed: strict
# frozen_string_literal: true

module OpenRouter
  # Response wrapper for OpenRouter API responses
  class Response
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :success

    sig { returns(T.nilable(String)) }
    attr_reader :content

    sig { returns(T.nilable(T::Hash[String, T.untyped])) }
    attr_reader :usage

    sig { returns(T.nilable(Error)) }
    attr_reader :error

    sig { returns(T.nilable(T::Hash[String, T.untyped])) }
    attr_reader :raw_response

    sig do
      params(
        success: T::Boolean,
        content: T.nilable(String),
        usage: T.nilable(T::Hash[String, T.untyped]),
        error: T.nilable(Error),
        raw_response: T.nilable(T::Hash[String, T.untyped])
      ).void
    end
    def initialize(success:, content: nil, usage: nil, error: nil, raw_response: nil)
      @success = success
      @content = content
      @usage = usage
      @error = error
      @raw_response = raw_response
    end

    sig { returns(T::Boolean) }
    def success?
      @success
    end

    sig { returns(T::Boolean) }
    def failure?
      !@success
    end

    sig { returns(T.nilable(T::Hash[String, T.untyped])) }
    def content_as_json
      return nil if @content.nil?

      JSON.parse(@content)
    rescue JSON::ParserError => e
      raise ResponseParsingError, "Failed to parse response content: #{e.message}"
    end

    sig { returns(T.nilable(Integer)) }
    def total_tokens
      @usage&.dig('total_tokens')
    end

    sig { returns(T.nilable(Integer)) }
    def prompt_tokens
      @usage&.dig('prompt_tokens')
    end

    sig { returns(T.nilable(Integer)) }
    def completion_tokens
      @usage&.dig('completion_tokens')
    end

    # Factory method for successful responses
    sig do
      params(
        content: String,
        usage: T::Hash[String, T.untyped],
        raw_response: T::Hash[String, T.untyped]
      ).returns(Response)
    end
    def self.success(content:, usage:, raw_response:)
      new(
        success: true,
        content:,
        usage:,
        raw_response:
      )
    end

    # Factory method for error responses
    sig { params(error: Error).returns(Response) }
    def self.failure(error:)
      new(
        success: false,
        error:
      )
    end
  end
end
