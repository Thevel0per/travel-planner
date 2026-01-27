import "@typespec/http";
import "@typespec/openapi3";

using TypeSpec.Http;

namespace TravelPlanner;

// Note model - represents a note associated with a trip
model Note {
  id: int64;
  trip_id: int64;
  content: string;
  created_at: utcDateTime;
  updated_at: utcDateTime;
}

// Request/Response wrappers
model NoteResponse {
  note: Note;
}

model NoteCreateRequest {
  note: {
    content: string;
  };
}

model NoteUpdateRequest {
  note: {
    content: string;
  };
}

model NoteDeleteResponse {
  message: string;
}

// Error response
model ErrorResponse {
  errors: Record<string[]>;
}

// API Operations for Notes under Trips
@route("/trips/{trip_id}/notes")
namespace Notes {
  @post
  op create(
    @path trip_id: int64,
    @body request: NoteCreateRequest
  ): NoteResponse | ErrorResponse;
  
  @patch
  op update(
    @path trip_id: int64,
    @path id: int64,
    @body request: NoteUpdateRequest
  ): NoteResponse | ErrorResponse;
  
  @delete
  op destroy(
    @path trip_id: int64,
    @path id: int64
  ): NoteDeleteResponse | ErrorResponse;
}
