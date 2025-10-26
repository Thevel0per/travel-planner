class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include Pagy backend for pagination
  include Pagy::Backend

  # Comprehensive error handling for all controllers
  rescue_from StandardError, with: :handle_server_error
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from Pagy::OverflowError, with: :handle_pagination_overflow

  private

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
  # @param dto_class [Class] The DTO class to use for transformation
  # @param pagy [Pagy] The Pagy object with pagination metadata
  # @param transform_method [Symbol] The method to call on the DTO class (default: :from_model)
  def render_paginated_json(collection, dto_class:, pagy:, transform_method: :from_model, key: :items)
    # Transform each item to DTO
    items_data = collection.map { |item| dto_class.send(transform_method, item) }

    # Build pagination metadata from Pagy object
    meta_data = DTOs::PaginationMetaDTO.build(
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    )

    render json: {
      key => items_data.map(&:serialize),
      meta: meta_data.serialize
    }, status: :ok
  end

  # Renders a single model as JSON using a DTO
  def render_model_json(model, dto_class:, transform_method: :from_model, status: :ok)
    dto = dto_class.send(transform_method, model)
    render json: dto.serialize, status:
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
    error_dto = DTOs::ErrorResponseDTO.validation_errors(errors_hash)

    respond_to do |format|
      format.json { render json: error_dto.serialize, status: :bad_request }
      format.html do
        flash[:alert] = format_errors_for_flash(errors_hash)
        redirect_to redirect_path || request.referer || root_path
      end
    end
  end

  # Handles bad request errors (e.g., missing required parameters)
  def handle_bad_request(exception)
    Rails.logger.warn("Bad request in #{controller_name}##{action_name}: #{exception.message}")

    error_dto = DTOs::ErrorResponseDTO.single_error(exception.message)

    respond_to do |format|
      format.json { render json: error_dto.serialize, status: :bad_request }
      format.html do
        flash[:alert] = exception.message
        redirect_to request.referer || root_path
      end
    end
  end

  # Handles not found errors (e.g., record not found)
  def handle_not_found(exception)
    Rails.logger.warn("Not found in #{controller_name}##{action_name}: #{exception.message}")

    error_dto = DTOs::ErrorResponseDTO.single_error('Resource not found')

    respond_to do |format|
      format.json { render json: error_dto.serialize, status: :not_found }
      format.html do
        flash[:alert] = 'Resource not found'
        redirect_to root_path
      end
    end
  end

  # Handles pagination overflow (page number too high)
  def handle_pagination_overflow(_exception = nil)
    error_message = 'Page number exceeds available pages'
    error_dto = DTOs::ErrorResponseDTO.single_error(error_message)

    respond_to do |format|
      format.json { render json: error_dto.serialize, status: :bad_request }
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

    error_dto = DTOs::ErrorResponseDTO.single_error('An unexpected error occurred')

    respond_to do |format|
      format.json { render json: error_dto.serialize, status: :internal_server_error }
      format.html do
        flash[:alert] = 'An unexpected error occurred'
        redirect_to root_path
      end
    end
  end

  # Formats error hash for flash messages
  def format_errors_for_flash(errors_hash)
    errors_hash.flat_map do |field, messages|
      messages.map { |msg| field == 'base' ? msg : "#{field.humanize}: #{msg}" }
    end.join(', ')
  end
end
