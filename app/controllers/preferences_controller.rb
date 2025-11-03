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
end
