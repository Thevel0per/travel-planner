# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for pagination metadata
  # Included in paginated API responses
  class PaginationMetaDTO < T::Struct
    extend T::Sig
    include BaseDTO

    const :current_page, Integer
    const :total_pages, Integer
    const :total_count, Integer
    const :per_page, Integer

    sig do
      params(
        current_page: Integer,
        total_pages: Integer,
        total_count: Integer,
        per_page: Integer
      ).returns(PaginationMetaDTO)
    end
    def self.build(current_page:, total_pages:, total_count:, per_page:)
      new(
        current_page:,
        total_pages:,
        total_count:,
        per_page:
      )
    end

    sig { params(collection: T.untyped).returns(PaginationMetaDTO) }
    def self.from_collection(collection)
      # Works with Kaminari or will_paginate or similar pagination gems
      new(
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      )
    end
  end
end
