# typed: strict
# frozen_string_literal: true

# Service object for building and executing Trip queries with filtering, sorting, and pagination
# Extracts query logic from controller to keep it thin and testable
class TripsQueryService
  extend T::Sig

  # Constants for parameter validation
  ALLOWED_SORT_ORDERS = T.let(%w[asc desc].freeze, T::Array[String])
  DEFAULT_SORT_ORDER = T.let('asc', String)
  DEFAULT_PER_PAGE = T.let(20, Integer)
  MIN_PER_PAGE = T.let(1, Integer)
  MAX_PER_PAGE = T.let(100, Integer)
  MIN_PAGE = T.let(1, Integer)

  sig { params(user: User, params: ActionController::Parameters).void }
  def initialize(user, params)
    @user = user
    @params = params
    @errors = T.let([], T::Array[String])
  end

  # Validates all query parameters
  # Returns true if valid, false otherwise
  # Errors can be accessed via #errors method
  sig { returns(T::Boolean) }
  def valid?
    @errors = []
    validate_sort_order
    validate_per_page
    validate_page
    @errors.empty?
  end

  # Returns array of validation error messages
  sig { returns(T::Array[String]) }
  attr_reader :errors

  # Builds the base query with filters and sorting applied
  # Does NOT apply pagination - that's handled by controller with Pagy
  sig { returns(ActiveRecord::Relation) }
  def call
    query = @user.trips

    # Apply destination filter if provided
    query = apply_destination_filter(query) if destination.present?

    # Apply sorting
    query = apply_sorting(query)

    query
  end

  # Getter methods for validated parameters

  sig { returns(Integer) }
  def page
    [ @params[:page].to_i, MIN_PAGE ].max
  end

  sig { returns(Integer) }
  def per_page
    value = @params[:per_page].to_i
    return DEFAULT_PER_PAGE if value.zero?

    value.clamp(MIN_PER_PAGE, MAX_PER_PAGE)
  end

  sig { returns(String) }
  def sort_order
    order = @params[:sort_order]&.to_s&.downcase
    ALLOWED_SORT_ORDERS.include?(order) ? order : DEFAULT_SORT_ORDER
  end

  sig { returns(T.nilable(String)) }
  def destination
    @params[:destination]&.to_s&.strip
  end

  private

  sig { void }
  def validate_sort_order
    return if @params[:sort_order].blank?

    order = @params[:sort_order].to_s.downcase
    unless ALLOWED_SORT_ORDERS.include?(order)
      @errors << "sort_order must be either 'asc' or 'desc'"
    end
  end

  sig { void }
  def validate_per_page
    return if @params[:per_page].blank?

    value = @params[:per_page].to_i
    if value < MIN_PER_PAGE || value > MAX_PER_PAGE
      @errors << "per_page must be between #{MIN_PER_PAGE} and #{MAX_PER_PAGE}"
    end
  end

  sig { void }
  def validate_page
    return if @params[:page].blank?

    value = @params[:page].to_i
    if value < MIN_PAGE
      @errors << 'page must be a positive integer'
    end
  end

  sig { params(query: ActiveRecord::Relation).returns(ActiveRecord::Relation) }
  def apply_destination_filter(query)
    # Use parameterized query to prevent SQL injection
    # ILIKE is PostgreSQL case-insensitive pattern matching
    query.where('destination ILIKE ?', "%#{sanitize_sql_like(destination)}%")
  end

  sig { params(query: ActiveRecord::Relation).returns(ActiveRecord::Relation) }
  def apply_sorting(query)
    # Default sort by start_date with configurable order
    query.order(start_date: sort_order.to_sym)
  end

  # Sanitize string for SQL LIKE queries to prevent SQL injection
  sig { params(string: T.nilable(String)).returns(String) }
  def sanitize_sql_like(string)
    return '' if string.nil?

    # Escape special SQL LIKE characters
    ActiveRecord::Base.sanitize_sql_like(string)
  end
end
