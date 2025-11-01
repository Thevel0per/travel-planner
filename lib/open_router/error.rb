# typed: strict
# frozen_string_literal: true

module OpenRouter
  # Base error class for all OpenRouter errors
  class Error < StandardError
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :retryable

    sig { params(message: String, retryable: T::Boolean).void }
    def initialize(message = '', retryable: false)
      super(message)
      @retryable = retryable
    end

    sig { returns(T::Boolean) }
    def retryable?
      @retryable
    end
  end

  # Authentication error (401)
  class AuthenticationError < Error
    sig { params(message: String).void }
    def initialize(message = 'Invalid API key')
      super(message, retryable: false)
    end
  end

  # Rate limit error (429)
  class RateLimitError < Error
    extend T::Sig

    sig { returns(T.nilable(Integer)) }
    attr_reader :retry_after

    sig { params(message: String, retry_after: T.nilable(Integer)).void }
    def initialize(message = 'Rate limit exceeded', retry_after: nil)
      super(message, retryable: true)
      @retry_after = retry_after
    end
  end

  # Server error (5xx)
  class ServerError < Error
    sig { params(message: String, status_code: T.nilable(Integer)).void }
    def initialize(message = 'Server error', status_code: nil)
      @status_code = status_code
      super(message, retryable: true)
    end

    sig { returns(T.nilable(Integer)) }
    attr_reader :status_code
  end

  # Timeout error
  class TimeoutError < Error
    sig { params(message: String).void }
    def initialize(message = 'Request timeout')
      super(message, retryable: true)
    end
  end

  # Network error
  class NetworkError < Error
    sig { params(message: String).void }
    def initialize(message = 'Network connection failed')
      super(message, retryable: true)
    end
  end

  # Response parsing error
  class ResponseParsingError < Error
    sig { params(message: String).void }
    def initialize(message = 'Invalid JSON response')
      super(message, retryable: false)
    end
  end

  # Client error (4xx, excluding 401 and 429)
  class ClientError < Error
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :status_code

    sig { params(message: String, status_code: Integer).void }
    def initialize(message = 'Client error', status_code: 400)
      super(message, retryable: false)
      @status_code = status_code
    end
  end

  # Configuration error
  class ConfigurationError < Error
    sig { params(message: String).void }
    def initialize(message = 'Invalid configuration')
      super(message, retryable: false)
    end
  end
end

