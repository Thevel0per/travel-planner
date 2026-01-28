class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include Pagy backend for pagination
  include Pagy::Backend

  # Comprehensive error handling for all controllers
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from Pagy::OverflowError, with: :handle_pagination_overflow

  # Use Devise layout for authentication pages, application layout for authenticated pages
  layout :layout_by_resource

  private

  # Determines which layout to use based on whether it's a Devise controller
  def layout_by_resource
    devise_controller? ? 'devise' : 'application'
  end

  # Paginates a query service and handles validation
  # @param query_service [Object] A query service object with valid?, errors, page, per_page, and call methods
  # @param redirect_path [String] Optional path to redirect to on validation error (HTML only)
  # @return [Array<Pagy, ActiveRecord::Relation>, nil] Returns [pagy, collection] on success, nil on validation error
  def apply_pagination(query_service, redirect_path: nil)
    # Validate query parameters
    unless query_service.valid?
      handle_validation_errors(query_service.errors, redirect_path:)
      return nil
    end

    # Build query with filters and sorting
    collection = query_service.call

    # Apply pagination using Pagy
    pagy(
      collection,
      page: query_service.page,
      limit: query_service.per_page
    )
  end

  # Renders JSON response with pagination
  # @param collection [Array] The collection of model objects
  # @param serializer_class [Class] The Blueprinter serializer class to use
  # @param pagy [Pagy] The Pagy object with pagination metadata
  # @param view [Symbol] The view to use for serialization (optional)
  # @param options [Hash] Additional options to pass to the serializer
  def render_paginated_json(collection, serializer_class:, pagy:, view: nil, key: :items, **options)
    # Serialize collection with Blueprinter
    serializer_options = options.merge(view:).compact
    items_data = JSON.parse(serializer_class.render(collection, serializer_options))

    # Build pagination metadata from Pagy object
    meta_data = PaginationSerializer.from_pagy(pagy)

    render json: {
      key => items_data,
      meta: meta_data
    }, status: :ok
  end

  # Renders a single model as JSON using a Blueprinter serializer
  def render_model_json(model, serializer_class:, view: nil, status: :ok, **options)
    serializer_options = options.merge(view:).compact
    render json: serializer_class.render(model, serializer_options), status:
  end

  # Renders a success response with optional data
  def render_success(message: 'Success', data: nil, status: :ok)
    response = { message: }
    response[:data] = data if data
    render json: response, status:
  end

  # Handles validation errors from query services or models
  def handle_validation_errors(errors, redirect_path: nil)
    # Convert array of error messages to hash format if needed
    errors_hash = errors.is_a?(Array) ? { 'parameters' => errors } : errors
    error_response = ErrorSerializer.render_errors(errors_hash)

    respond_to do |format|
      format.json { render json: error_response, status: :bad_request }
      format.html do
        flash[:alert] = format_errors_for_flash(errors_hash)
        redirect_to redirect_path || request.referer || root_path
      end
    end
  end

  # Handles bad request errors (e.g., missing required parameters)
  def handle_bad_request(exception)
    Rails.logger.warn("Bad request in #{controller_name}##{action_name}: #{exception.message}")

    error_response = ErrorSerializer.render_error(exception.message)

    respond_to do |format|
      format.json { render json: error_response, status: :bad_request }
      format.html do
        flash[:alert] = exception.message
        redirect_to request.referer || root_path
      end
    end
  end

  # Handles not found errors (e.g., record not found)
  def handle_not_found(exception)
    Rails.logger.warn("Not found in #{controller_name}##{action_name}: #{exception.message}")

    error_response = ErrorSerializer.render_error('Resource not found')

    respond_to do |format|
      format.json { render json: error_response, status: :not_found }
      format.html do
        flash[:alert] = 'Resource not found'
        redirect_to root_path
      end
    end
  end

  # Handles pagination overflow (page number too high)
  def handle_pagination_overflow(_exception = nil)
    error_message = 'Page number exceeds available pages'
    error_response = ErrorSerializer.render_error(error_message)

    respond_to do |format|
      format.json { render json: error_response, status: :bad_request }
      format.html do
        flash[:alert] = error_message
        redirect_to request.referer || root_path
      end
    end
  end

  # Handles unexpected server errors
  def handle_server_error(exception)
    Rails.logger.error("Unexpected error in #{controller_name}##{action_name}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    error_response = ErrorSerializer.render_error('An unexpected error occurred')

    respond_to do |format|
      format.json { render json: error_response, status: :internal_server_error }
      format.html do
        flash[:alert] = 'An unexpected error occurred'
        redirect_to root_path
      end
    end
  end

  # Formats error hash for flash messages
  def format_errors_for_flash(errors_hash)
    errors_hash.flat_map do |field, messages|
      field_str = field.to_s
      messages.map { |msg| field_str == 'base' ? msg : "#{field_str.humanize}: #{msg}" }
    end.join(', ')
  end
end
