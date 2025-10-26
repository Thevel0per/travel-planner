# typed: strict
# frozen_string_literal: true

module Commands
  # Command Model for updating an existing note
  # Used by PUT/PATCH /trips/:trip_id/notes/:id endpoint
  # Derived from: notes table (subset of fields)
  class NoteUpdateCommand < T::Struct
    include BaseDTO
    extend T::Sig

    const :content, String

    sig { params(params: T::Hash[T.untyped, T.untyped]).returns(NoteUpdateCommand) }
    def self.from_params(params)
      note_params = params[:note] || params
      new(content: note_params[:content])
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_model_attributes
      { content: }
    end
  end
end
