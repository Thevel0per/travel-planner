import "@typespec/http";
import "@typespec/openapi3";

// Import all resource definitions
import "./trips.tsp";
import "./notes.tsp";
import "./preferences.tsp";
import "./generated_plans.tsp";

using TypeSpec.Http;

@service({
  title: "Travel Planner API",
})
namespace TravelPlanner;
