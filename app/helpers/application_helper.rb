module ApplicationHelper
  # Include Pagy frontend helper for pagination
  include Pagy::Frontend

  # Helper methods for preference form options

  # Returns array of [label, value] pairs for budget select dropdown
  def budget_options
    UserPreference::BUDGETS.map do |value|
      [ value.humanize.titleize, value ]
    end
  end

  # Returns array of [label, value] pairs for accommodation select dropdown
  def accommodation_options
    UserPreference::ACCOMMODATIONS.map do |value|
      [ value.humanize.titleize, value ]
    end
  end

  # Returns array of [label, value] pairs for activity checkboxes
  def activity_options
    UserPreference::ACTIVITIES.map do |value|
      [ value.humanize.titleize, value ]
    end
  end

  # Returns array of [label, value] pairs for eating habits select dropdown
  def eating_habits_options
    UserPreference::EATING_HABITS.map do |value|
      # Custom labels for eating habits
      label = case value
      when 'restaurants_only'
                'Restaurants Only'
      when 'self_prepared'
                'Self-Prepared'
      when 'mix'
                'Mix'
      else
                value.humanize.titleize
      end
      [ label, value ]
    end
  end
end
