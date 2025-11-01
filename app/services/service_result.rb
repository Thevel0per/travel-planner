# typed: strict
# frozen_string_literal: true

# Generic result object for service responses
class ServiceResult
  extend T::Sig

  sig { returns(T::Boolean) }
  attr_reader :success

  sig { returns(T.untyped) }
  attr_reader :data

  sig { returns(T.nilable(String)) }
  attr_reader :error_message

  sig { returns(T::Boolean) }
  attr_reader :retryable

  sig do
    params(
      success: T::Boolean,
      data: T.untyped,
      error_message: T.nilable(String),
      retryable: T::Boolean
    ).void
  end
  def initialize(success:, data: nil, error_message: nil, retryable: false)
    @success = success
    @data = data
    @error_message = error_message
    @retryable = retryable
  end

  sig { returns(T::Boolean) }
  def success?
    @success
  end

  sig { returns(T::Boolean) }
  def failure?
    !@success
  end

  sig { returns(T::Boolean) }
  def retryable?
    @retryable
  end

  # Factory methods
  sig { params(data: T.untyped).returns(ServiceResult) }
  def self.success(data: nil)
    new(success: true, data:)
  end

  sig do
    params(
      error_message: String,
      retryable: T::Boolean
    ).returns(ServiceResult)
  end
  def self.failure(error_message:, retryable: false)
    new(success: false, error_message:, retryable:)
  end
end
