# typed: strict
# frozen_string_literal: true

module Commands
  # Command Model for creating a new note
  # Used by POST /trips/:trip_id/notes endpoint
  # Derived from: notes table (subset of fields)
  class NoteCreateCommand < T::Struct
    include BaseDTO
    extend T::Sig

    const :content, String

    sig { params(params: T::Hash[T.untyped, T.untyped]).returns(NoteCreateCommand) }
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
