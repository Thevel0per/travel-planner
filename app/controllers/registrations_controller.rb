# typed: strict
# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  extend T::Sig

  # Override redirect paths for registration flow
  protected

  # Redirect after successful sign up (when user is active/confirmed)
  sig { params(_resource: User).returns(String) }
  def after_sign_up_path_for(_resource)
    root_path
  end

  # Redirect after sign up when user is inactive (needs email confirmation)
  sig { params(_resource: User).returns(String) }
  def after_inactive_sign_up_path_for(_resource)
    new_user_confirmation_path
  end

  sig { params(_resource: User).returns(String) }
  def after_update_path_for(_resource)
    profile_path(tab: 'account')
  end

  # Override update_resource to allow email updates without current_password
  # when password is not being changed
  # Note: Devise may pass either ActionController::Parameters or HashWithIndifferentAccess
  # We use T.unsafe to bypass Sorbet type checking since Devise's signature may vary
  def update_resource(resource, params)
    # Convert to hash for consistent handling
    params_hash = if params.is_a?(ActionController::Parameters)
                    params.to_h.with_indifferent_access
                  else
                    params.to_h.with_indifferent_access
                  end
    
    # If password is blank, we're only updating email - skip current_password requirement
    if params_hash[:password].blank? && params_hash[:password_confirmation].blank?
      # Create hash without current_password, password, and password_confirmation
      # update_without_password accepts a hash
      update_params = params_hash.except(:current_password, :password, :password_confirmation)
      T.unsafe(resource).update_without_password(update_params)
    else
      # Password is being changed - require current_password (default Devise behavior)
      # Convert params to hash for update_with_password if needed
      password_params = if params.is_a?(ActionController::Parameters)
                          params.to_h.with_indifferent_access
                        else
                          params.to_h.with_indifferent_access
                        end
      T.unsafe(resource).update_with_password(password_params)
    end
  end
end

