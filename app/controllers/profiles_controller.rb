# typed: strict
# frozen_string_literal: true

class ProfilesController < ApplicationController
  extend T::Sig

  # Ensure user is authenticated before accessing profile
  before_action :authenticate_user!

  # GET /profile
  # Renders the Profile & Preferences page with tabbed interface
  # Supports URL parameters: ?tab=account or ?tab=preferences
  sig { void }
  def show
    # Load user preferences (can be nil if preferences don't exist yet)
    @user_preferences = current_user.user_preference

    # Determine active tab from URL parameter, default to 'preferences'
    @active_tab = params[:tab] || 'preferences'

    # Ensure active_tab is valid ('account' or 'preferences')
    @active_tab = 'preferences' unless %w[account preferences].include?(@active_tab)
  end
end
