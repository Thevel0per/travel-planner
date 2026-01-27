import "@typespec/http";
import "@typespec/openapi3";

using TypeSpec.Http;

namespace TravelPlanner;

// Enum for generated plan status
enum GeneratedPlanStatus {
  pending: "pending",
  generating: "generating",
  completed: "completed",
  failed: "failed",
}

// Activity within a day's itinerary (for generated plans)
model PlanActivity {
  time: string; // e.g., "10:00 AM"
  name: string;
  duration_minutes: int32;
  estimated_cost_usd: float64;
  estimated_cost_per_person_usd: float64;
  rating: float64; // 0.0-5.0
  description: string;
  google_maps_url?: string; // Optional Google Maps URL
}

// Restaurant recommendation for a meal
model Restaurant {
  meal: string; // "breakfast", "lunch", "dinner"
  name: string;
  cuisine: string;
  estimated_cost_per_person_usd: float64;
  rating: float64; // 0.0-5.0
  google_maps_url?: string; // Optional Google Maps URL
}

// Daily itinerary with activities and restaurants
model DailyItinerary {
  day: int32; // Day number (1, 2, 3, etc.)
  date: string; // ISO 8601 date format (YYYY-MM-DD)
  activities: PlanActivity[];
  restaurants: Restaurant[];
}

// Hotel recommendation
model Hotel {
  name: string;
  location: string; // Address or location description
  estimated_cost_per_night_usd: float64;
  rating: float64; // 0.0-5.0
  google_maps_url?: string; // Optional Google Maps URL
  description?: string; // Optional description
}

// Summary information for the entire trip
model TripSummary {
  total_cost_usd: float64;
  cost_per_person_usd: float64;
  duration_days: int32;
  number_of_people: int32;
}

// Complete generated plan content structure
model GeneratedPlanContent {
  summary: TripSummary;
  hotels: Hotel[]; // Recommended hotels
  daily_itinerary: DailyItinerary[];
}

// GeneratedPlan model - list view (without full content)
model GeneratedPlanListItem {
  id: int64;
  trip_id: int64;
  status: GeneratedPlanStatus;
  rating?: int32; // 1-10, nullable
  created_at: utcDateTime;
  updated_at: utcDateTime;
}

// GeneratedPlan model - detail view (with full content)
model GeneratedPlanDetail {
  id: int64;
  trip_id: int64;
  status: GeneratedPlanStatus;
  rating?: int32; // 1-10, nullable
  created_at: utcDateTime;
  updated_at: utcDateTime;
  content?: GeneratedPlanContent; // Only present when status is 'completed'
}

// Request/Response wrappers
model GeneratedPlanResponse {
  generated_plan: GeneratedPlanListItem;
  message?: string;
}

model GeneratedPlanDetailResponse {
  generated_plan: GeneratedPlanDetail;
  message?: string;
}

model GeneratedPlanCreateResponse {
  generated_plan: GeneratedPlanListItem;
  message: string;
}

model GeneratedPlanUpdateRequest {
  generated_plan: {
    rating?: int32; // 1-10
  };
}

model GeneratedPlanValidationErrorResponse {
  errors: Record<string[]>;
}

// API Operations for GeneratedPlans under Trips
@route("/trips/{trip_id}/generated_plans")
namespace GeneratedPlans {
  @post
  op create(
    @path trip_id: int64
  ): {
    @statusCode statusCode: 202;
    @body body: GeneratedPlanCreateResponse;
  };
  
  @get
  op show(
    @path trip_id: int64,
    @path id: int64
  ): GeneratedPlanDetailResponse;
  
  @patch
  op update(
    @path trip_id: int64,
    @path id: int64,
    @body request: GeneratedPlanUpdateRequest
  ): GeneratedPlanDetailResponse;
}
