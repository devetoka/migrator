# frozen_string_literal: true

class Import < ActiveRecord::Base
  belongs_to :hospital
  before_validation :set_name

  validates :name, presence: true
  validates :yaml_content, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }


  enum import_type: { basic_info: 'basic_info', vital: 'vital'}
  private
  def set_name
    initials = hospital.code
    date = Date.today.to_s
    self.name ||= "#{initials}-#{date}-import.#{rand(1000..5000)}"
  end
end
