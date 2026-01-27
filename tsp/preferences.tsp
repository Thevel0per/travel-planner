import "@typespec/http";
import "@typespec/openapi3";

using TypeSpec.Http;

namespace TravelPlanner;

// Enum definitions for preference options

/** Budget preference levels */
enum Budget {
  /** Budget-conscious travel */
  BudgetConscious: "budget_conscious",
  /** Standard budget */
  Standard: "standard",
  /** Luxury travel */
  Luxury: "luxury",
}

/** Accommodation types */
enum Accommodation {
  /** Hotel accommodation */
  Hotel: "hotel",
  /** Airbnb rental */
  Airbnb: "airbnb",
  /** Hostel accommodation */
  Hostel: "hostel",
  /** Resort accommodation */
  Resort: "resort",
  /** Camping accommodation */
  Camping: "camping",
}

/** Activity preferences */
enum Activity {
  /** Outdoor activities */
  Outdoors: "outdoors",
  /** Sightseeing */
  Sightseeing: "sightseeing",
  /** Cultural activities */
  Cultural: "cultural",
  /** Relaxation activities */
  Relaxation: "relaxation",
  /** Adventure activities */
  Adventure: "adventure",
  /** Nightlife activities */
  Nightlife: "nightlife",
  /** Shopping activities */
  Shopping: "shopping",
}

/** Eating habit preferences */
enum EatingHabit {
  /** Restaurants only */
  RestaurantsOnly: "restaurants_only",
  /** Self-prepared meals */
  SelfPrepared: "self_prepared",
  /** Mix of restaurants and self-prepared */
  Mix: "mix",
}

// UserPreferences model - represents a user's travel preferences
model UserPreferences {
  id: int64;
  user_id: int64;
  budget?: Budget | null;
  accommodation?: Accommodation | null;
  activities?: string | null; // Comma-separated string of Activity values
  eating_habits?: EatingHabit | null;
  created_at: utcDateTime;
  updated_at: utcDateTime;
}

// PreferenceOptions model - available values for each preference category
model PreferenceOptions {
  budget: string[];
  accommodation: string[];
  activities: string[];
  eating_habits: string[];
}

// Request/Response wrappers
model UserPreferencesResponse {
  preferences: UserPreferences;
}

model PreferenceOptionsResponse {
  options: PreferenceOptions;
}

model PreferencesUpdateRequest {
  preferences: {
    budget?: Budget | null;
    accommodation?: Accommodation | null;
    activities?: string | null; // Comma-separated string of Activity values
    eating_habits?: EatingHabit | null;
  };
}

// Error response
model ErrorResponse {
  errors: Record<string[]>;
}

// API Operations for Preferences
@route("/preferences")
namespace Preferences {
  @get
  op show(): UserPreferencesResponse | ErrorResponse;
  
  @patch
  op update(@body request: PreferencesUpdateRequest): UserPreferencesResponse | ErrorResponse;
}

@route("/preferences/options")
namespace PreferenceOptions {
  @get
  op index(): PreferenceOptionsResponse;
}
