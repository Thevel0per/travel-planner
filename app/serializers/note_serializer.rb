# frozen_string_literal: true

# Serializer for Note resources
# Implements TypeSpec Note model from tsp/notes.tsp
class NoteSerializer < ApplicationSerializer
  identifier :id

  fields :trip_id, :content

  # Format timestamps as ISO 8601
  field :created_at do |note|
    note.created_at.iso8601
  end

  field :updated_at do |note|
    note.updated_at.iso8601
  end
end
