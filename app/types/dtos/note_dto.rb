# typed: strict
# frozen_string_literal: true

module DTOs
  # Data Transfer Object for Note resource
  # Represents note data as returned by the API
  # Derived from: notes table
  class NoteDTO < T::Struct
    extend T::Sig
    include BaseDTO

    # All attributes from notes table
    const :id, Integer
    const :trip_id, Integer
    const :content, String
    const :created_at, String # ISO 8601 datetime format
    const :updated_at, String # ISO 8601 datetime format

    sig { params(note: Note).returns(NoteDTO) }
    def self.from_model(note)
      new(
        id: note.id,
        trip_id: note.trip_id,
        content: note.content,
        created_at: note.created_at.iso8601,
        updated_at: note.updated_at.iso8601
      )
    end
  end
end
