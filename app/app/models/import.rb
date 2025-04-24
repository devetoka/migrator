# frozen_string_literal: true

class Import < ActiveRecord::Base
  belongs_to :hospital
  before_validation :set_name

  validates :name, presence: true, uniqueness: { scope: :hospital_id, message: "is already taken for this hospital" }
  validates :yaml_content, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }


  enum import_type: { basic_info: 'basic_info', vital: 'vital'}
  private
  def set_name
    initials = hospital.code
    date = Date.today.to_s
    self.name ||= "#{initials}-#{date}-import"
  end
end
