source 'https://rubygems.org'

# Core Framework - Rails 8.x with modern defaults
gem 'rails', '~> 8.0.2', '>= 8.0.2.1'

# Asset Pipeline - Modern propshaft for serving static assets
gem 'propshaft'

# Database - PostgreSQL for production-ready relational data
gem 'pg', '~> 1.1'

# Web Server - Puma for multi-threaded request handling
gem 'puma', '>= 5.0'

# JavaScript Management - Import maps for ESM modules without bundlers
gem 'importmap-rails'

# Hotwire Stack - Modern SPA-like interactions without heavy JS frameworks
gem 'turbo-rails'    # Turbo Drive, Frames, and Streams for dynamic updates
gem 'stimulus-rails' # Lightweight JS for sprinkles of interactivity

# CSS Framework - Utility-first Tailwind CSS
gem 'tailwindcss-rails'

# Platform-specific - Timezone data for Windows/JRuby
gem 'tzinfo-data', platforms: %i[ windows jruby ]

# Solid Suite - Database-backed Rails 8 defaults for caching, jobs, and websockets
gem 'solid_cache'  # Active Support cache backend
gem 'solid_queue' # Active Job backend for background processing

# Performance - Speeds up boot time by caching expensive operations
gem 'bootsnap', require: false

# Deployment - Docker deployment tool (has config but may use Kubernetes instead)
# Used for docker-based deployments, .kamal config exists
gem 'kamal', require: false

# Production Performance - HTTP caching and X-Sendfile for Puma
gem 'thruster', require: false

# Authentication - Devise for user registration, login, and session management
gem 'devise', '~> 4.9'

# Type Checking - Sorbet runtime for gradual typing (has RBI files)
gem 'sorbet-runtime'

# Pagination - Lightweight pagination in controllers and views
gem 'pagy', '~> 9.0'

# JSON Serialization - API response formatting with Blueprinter
gem 'blueprinter', '~> 1.2'

group :development, :test do
  # Debugging - Interactive debugger for troubleshooting
  gem 'debug', platforms: %i[ mri windows ], require: 'debug/prelude'

  # Security - Static analysis to detect security vulnerabilities
  gem 'brakeman', require: false

  # Code Quality - Ruby style guide enforcement (Rails Omakase preset)
  gem 'rubocop-rails-omakase', require: false

  # Testing Framework - RSpec for behavior-driven testing
  gem 'rspec-rails', '~> 7.0'

  # Test Data - Factory Bot for creating test objects
  gem 'factory_bot_rails', '~> 6.4'

  # Test Matchers - Shoulda for concise model and controller testing
  gem 'shoulda-matchers', '~> 6.0'

  # HTTP Mocking - WebMock for stubbing external API calls
  gem 'webmock', '~> 3.23'

  # System Testing - Capybara for browser-based feature tests
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver' # WebDriver for browser automation

  # Code Coverage - SimpleCov for test coverage reports
  gem 'simplecov', '~> 0.22.0', require: false

  # Test Reliability - Auto-retry for flaky tests
  gem 'rspec-retry', '~> 0.6.2'

  # Type Checking - Sorbet static type checker and RBI generator
  gem 'sorbet'
  gem 'tapioca', require: false
end

group :development do
  # Development UI - Interactive console on exception pages
  gem 'web-console'
end
