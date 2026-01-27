# frozen_string_literal: true

# Serializer for GeneratedPlan resources
# Supports both list view (without content) and detail view (with full content)
class GeneratedPlanSerializer < ApplicationSerializer
  identifier :id

  fields :trip_id, :status, :rating

  # Format timestamps as ISO 8601
  field :created_at do |plan|
    plan.created_at.iso8601
  end

  field :updated_at do |plan|
    plan.updated_at.iso8601
  end

  # Content field - only include for detail view when status is 'completed'
  # Uses GeneratedPlanContentSerializer to handle nested JSON structure
  field :content, if: ->(_, plan, options) { options[:detail] && plan.status == 'completed' && plan.content.present? } do |plan|
    parsed_content = GeneratedPlanContentSerializer.parse_content(plan.content)
    GeneratedPlanContentSerializer.render_as_hash(parsed_content) if parsed_content
  end

  # Class method for list view (without content)
  def self.for_list(plan)
    render_as_hash(plan, detail: false)
  end

  # Class method for detail view (with content)
  def self.for_detail(plan)
    render_as_hash(plan, detail: true)
  end
end
