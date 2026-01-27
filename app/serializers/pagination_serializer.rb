# frozen_string_literal: true

# Serializer for pagination metadata
# Used with Pagy gem to provide pagination information in API responses
class PaginationSerializer < Blueprinter::Base
  field :current_page
  field :total_pages
  field :total_count
  field :per_page

  class << self
    # Render pagination metadata from Pagy object
    # @param pagy [Pagy] Pagy pagination object
    # @return [Hash] Hash with pagination metadata
    def from_pagy(pagy)
      metadata = {
        current_page: pagy.page,
        total_pages: pagy.pages,
        total_count: pagy.count,
        per_page: pagy.limit
      }
      render_as_hash(metadata)
    end
  end
end
