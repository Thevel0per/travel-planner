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
    # Parse request parameters using command object
    command = Commands::PreferencesUpdateCommand.from_params(params.permit!.to_h)
    attributes = command.to_model_attributes

    # Find or initialize user preferences (upsert pattern)
    user_preference = current_user.user_preference || current_user.build_user_preference
    user_preference.assign_attributes(attributes)

    # Save (activates model validations)
    if user_preference.save
      # Success: Return 200 OK with preferences DTO
      respond_to do |format|
        format.json do
          dto = DTOs::UserPreferencesDTO.from_model(user_preference)
          render json: { preferences: dto.serialize }, status: :ok
        end
        format.html do
          flash[:notice] = 'Preferences updated successfully'
          redirect_to preferences_path
        end
      end
    else
      # Validation failure: Return 422 Unprocessable Entity with error details
      respond_to do |format|
        format.json do
          error_dto = DTOs::ErrorResponseDTO.from_model_errors(user_preference)
          render json: error_dto.serialize, status: :unprocessable_content
        end
        format.html do
          flash[:alert] = 'Failed to update preferences'
          redirect_to preferences_path
        end
      end
    end
  end
end
