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
          error_dto = DTOs::ErrorResponseDTO.single_error(
            'Preferences not found. Please create your preferences.'
          )
          render json: error_dto.serialize, status: :not_found
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
        dto = DTOs::UserPreferencesDTO.from_model(@user_preferences)
        render json: { preferences: dto.serialize }, status: :ok
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
    # Convert activities array to comma-separated string if present
    processed_params = process_preferences_params(params.permit!.to_h)

    # Parse request parameters using command object
    command = Commands::PreferencesUpdateCommand.from_params(processed_params)
    attributes = command.to_model_attributes(processed_params)

    # Find or initialize user preferences (upsert pattern)
    @user_preferences = current_user.user_preference || current_user.build_user_preference
    @user_preferences.assign_attributes(attributes)

    # Save (activates model validations)
    if @user_preferences.save
      # Success: Return 200 OK with preferences DTO
      respond_to do |format|
        format.json do
          dto = DTOs::UserPreferencesDTO.from_model(@user_preferences)
          render json: { preferences: dto.serialize }, status: :ok
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
          error_dto = DTOs::ErrorResponseDTO.from_model_errors(@user_preferences)
          render json: error_dto.serialize, status: :unprocessable_content
        end
        format.html do
          # Render profile view with form errors
          # Set instance variables needed by the profile view
          @active_tab = 'preferences'
          # @user_preferences is already set above with errors
          render 'profiles/show', status: :unprocessable_content, layout: 'application'
        end
      end
    end
  end

  private

  # Converts activities array to comma-separated string if present
  # Handles both array format (from form checkboxes) and string format (from API)
  sig { params(params: T::Hash[T.untyped, T.untyped]).returns(T::Hash[T.untyped, T.untyped]) }
  def process_preferences_params(params)
    processed = params.dup
    preferences_params = processed[:preferences] || processed

    # Convert activities array to comma-separated string if it's an array
    if preferences_params.is_a?(Hash) && preferences_params[:activities].is_a?(Array)
      # Filter out empty strings (from hidden field)
      activities_array = preferences_params[:activities].reject(&:blank?)
      preferences_params[:activities] = activities_array.any? ? activities_array.join(',') : nil
    end

    processed
  end
end
