# typed: strict
# frozen_string_literal: true

class Trip < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :user
  has_many :notes, dependent: :destroy
  has_many :generated_plans, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :destination, presence: true, length: { maximum: 255 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :number_of_people, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :end_date_after_start_date

  private

  sig { void }
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date <= start_date
      errors.add(:end_date, 'must be after start date')
    end
  end
end
