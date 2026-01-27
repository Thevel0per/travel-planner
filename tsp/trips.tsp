import "@typespec/http";
import "@typespec/openapi3";

using TypeSpec.Http;

namespace TravelPlanner;

// Trip model - represents a travel trip
model Trip {
  id: int64;
  name: string;
  destination: string;
  start_date: plainDate;
  end_date: plainDate;
  number_of_people: int32;
  created_at: utcDateTime;
  updated_at: utcDateTime;
}

// Trip with counts - used in list view
model TripWithCounts extends Trip {
  notes_count?: int32;
  generated_plans_count?: int32;
}

// Trip with associations - used in detail view
model TripDetail extends Trip {
  notes: Note[];
  generated_plans: GeneratedPlan[];
}

// Pagination metadata
model PaginationMeta {
  current_page: int32;
  total_pages: int32;
  total_count: int32;
  per_page: int32;
}

// Request/Response wrappers
model TripListResponse {
  trips: TripWithCounts[];
  meta: PaginationMeta;
}

model TripResponse {
  trip: Trip;
}

model TripDetailResponse {
  trip: TripDetail;
}

model TripCreateRequest {
  trip: {
    name: string;
    destination: string;
    start_date: plainDate;
    end_date: plainDate;
    number_of_people?: int32;
  };
}

model TripUpdateRequest {
  trip: {
    name?: string;
    destination?: string;
    start_date?: plainDate;
    end_date?: plainDate;
    number_of_people?: int32;
  };
}

model TripDeleteResponse {
  message: string;
}

// Error response
model ErrorResponse {
  errors: Record<string[]>;
}

// API Operations for Trips
@route("/trips")
namespace Trips {
  @get
  op list(
    @query page?: int32,
    @query per_page?: int32,
    @query sort?: string,
    @query order?: string
  ): TripListResponse | ErrorResponse;
  
  @get
  op show(@path id: int64): TripDetailResponse | ErrorResponse;
  
  @post
  op create(@body request: TripCreateRequest): TripResponse | ErrorResponse;
  
  @patch
  op update(@path id: int64, @body request: TripUpdateRequest): TripResponse | ErrorResponse;
  
  @delete
  op destroy(@path id: int64): TripDeleteResponse | ErrorResponse;
}

// Note: GeneratedPlan model referenced above should be defined in generated_plans.tsp
// For now, we'll use a minimal definition to avoid circular dependencies
model GeneratedPlan {
  id: int64;
  trip_id: int64;
  status: string;
  created_at: utcDateTime;
  updated_at: utcDateTime;
}
