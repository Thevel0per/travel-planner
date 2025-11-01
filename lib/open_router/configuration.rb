# typed: strict
# frozen_string_literal: true

module OpenRouter
  # Configuration class for OpenRouter client
  class Configuration
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :api_key

    sig { returns(Integer) }
    attr_accessor :timeout

    sig { returns(Integer) }
    attr_accessor :max_retries

    sig { returns(T.nilable(T.any(Logger, ActiveSupport::Logger, ActiveSupport::BroadcastLogger))) }
    attr_accessor :logger

    sig { returns(String) }
    attr_accessor :api_url

    sig { void }
    def initialize
      @api_key = T.let(nil, T.nilable(String))
      @timeout = T.let(60, Integer)
      @max_retries = T.let(3, Integer)
      @logger = T.let(nil, T.nilable(T.any(Logger, ActiveSupport::Logger, ActiveSupport::BroadcastLogger)))
      @api_url = T.let('https://openrouter.ai/api/v1/chat/completions', String)
    end

    sig { returns(T::Boolean) }
    def valid?
      !api_key.nil? && !api_key.empty?
    end
  end

  class << self
    extend T::Sig

    sig { returns(Configuration) }
    def configuration
      @configuration ||= T.let(Configuration.new, T.nilable(Configuration))
    end

    sig { params(block: T.proc.params(config: Configuration).void).void }
    def configure(&block)
      yield(configuration)
    end

    sig { void }
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
