# typed: strict
# frozen_string_literal: true

class PreferencesController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated before accessing preferences
  before_action :authenticate_user!

  # GET /preferences
  # Retrieves the current authenticated user's travel preferences
  # Returns 200 OK with preferences data on success, 404 if preferences don't exist
  sig { void }
  def show
    @user_preferences = current_user.user_preference

    if @user_preferences.nil?
      # Return 404 with custom error message per API spec
      Rails.logger.warn("Preferences not found for user_id: #{current_user.id}")
      respond_to do |format|
        format.json do
          render json: ErrorSerializer.render_error(
            'Preferences not found. Please create your preferences.'
          ), status: :not_found
        end
        format.html do
          flash[:alert] = 'Preferences not found. Please create your preferences.'
          redirect_to root_path
        end
      end
      return
    end

    # Success: Transform and render
    respond_to do |format|
      format.json do
        render json: { preferences: UserPreferencesSerializer.render_as_hash(@user_preferences) }, status: :ok
      end
      format.html do
        # HTML view not implemented yet per requirements
        redirect_to root_path
      end
    end
  end

  # PUT/PATCH /preferences
  # Creates or updates the current authenticated user's travel preferences (upsert operation)
  # Returns 200 OK with preferences data on success, 422 on validation errors
  sig { void }
  def update
    # Find or initialize user preferences (upsert pattern)
    @user_preferences = current_user.user_preference || current_user.build_user_preference

    # Update with strong parameters
    if @user_preferences.update(preferences_params)
      # Success: Return 200 OK with preferences
      respond_to do |format|
        format.json do
          render json: { preferences: UserPreferencesSerializer.render_as_hash(@user_preferences) }, status: :ok
        end
        format.html do
          flash[:notice] = 'Preferences updated successfully'
          redirect_to profile_path(tab: 'preferences')
        end
      end
    else
      # Validation failure: Return 422 Unprocessable Entity with error details
      respond_to do |format|
        format.json do
          render json: ErrorSerializer.render_model_errors(@user_preferences), status: :unprocessable_content
        end
        format.html do
          flash[:alert] = 'Failed to update preferences'
          redirect_to profile_path(tab: 'preferences')
        end
      end
    end
  end

  private

  # Strong Parameters for Preferences
  # Handles conversion of activities array to comma-separated string
  # All fields are optional, so empty hash is allowed (no-op update)
  sig { returns(Hash) }
  def preferences_params
    # Fetch preferences, default to empty hash if not present
    prefs = params.fetch(:preferences, {})

    # Permit activities as both string (JSON API) and array (HTML form checkboxes)
    permitted = prefs.permit(:budget, :accommodation, :eating_habits, :activities, activities: [])
    result = permitted.to_h

    # Convert activities array to comma-separated string if it's an array
    # This handles form checkboxes that submit as arrays
    # Note: activities might be a string (from JSON) or array (from form checkboxes)
    if result[:activities].is_a?(Array)
      # Filter out empty strings (from hidden field)
      activities_array = result[:activities].reject(&:blank?)
      result[:activities] = activities_array.any? ? activities_array.join(',') : nil
    end

    # Convert empty strings to nil for optional fields
    # This allows clearing preferences by submitting empty values
    result.transform_values { |v| v.presence }
  end
end
