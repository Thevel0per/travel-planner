# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

# Base module for all Data Transfer Objects (DTOs)
# DTOs are immutable structs used to transfer data between layers of the application
# This module provides common functionality for all DTOs
module BaseDTO
  extend T::Sig
  extend T::Helpers

  # This module is meant to be included in T::Struct classes
  # It provides the serialize method for converting DTOs to hashes

  # Override this in including classes if needed
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def serialize
    self.class.props.keys.each_with_object({}) do |key, hash|
      value = public_send(key)
      hash[key] = serialize_value(value)
    end
  end

  private

  sig { params(value: T.untyped).returns(T.untyped) }
  def serialize_value(value)
    case value
    when T::Struct
      # If the struct has a serialize method, use it; otherwise convert to hash
      value.respond_to?(:serialize) ? value.serialize : value.serialize_helper
    when Array
      value.map { |v| serialize_value(v) }
    when Hash
      value.transform_values { |v| serialize_value(v) }
    else
      value
    end
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def serialize_helper
    self.class.props.keys.each_with_object({}) do |key, hash|
      value = public_send(key)
      hash[key] = serialize_value(value)
    end
  end
end
