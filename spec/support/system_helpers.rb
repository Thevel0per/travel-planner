# frozen_string_literal: true

module SystemHelpers
  # Helper to sign in a user in system tests
  def sign_in_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  # Helper to sign out current user
  def sign_out
    click_button 'Sign Out' if page.has_button?('Sign Out')
  end

  # Helper to wait for Turbo to finish loading
  def wait_for_turbo
    expect(page).to have_no_css('.turbo-progress-bar', wait: 5)
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.before(:each, type: :system) do
    # Use Selenium with headless Chrome (matches Rails defaults)
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end

  # Use transactional fixtures for system tests with Selenium
  # Selenium runs in a separate thread but shares the same database connection
  config.use_transactional_fixtures = true
end
