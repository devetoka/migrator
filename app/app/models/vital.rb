# frozen_string_literal: true
class Vital < ApplicationRecord
  belongs_to :patient, optional: true
  before_validation :convert_unit_measurement, :set_patient_from_medical_record_number

  attr_accessor :medical_record_number
  attr_accessor :hospital_id

  validates :vital_type, presence: {message: 'can not be empty'}, inclusion: { in: %w[weight height], message: "%{value} is not a valid vital type" }
  validates :unit, presence: {message: 'can not be empty'}
  validate :unit_is_valid_for_vital_type, if: -> { vital_type.present? }
  validate :require_patient_or_mrn


  VALID_HEIGHT_UNITS = %w[cm m in ft]
  VALID_WEIGHT_UNITS = %w[kg g lbs oz]


  private

  def is_weight?
    vital_type == 'weight'
  end

  def is_height?
    vital_type == 'height'
  end
  # All weights unit must be compatible.
  # here, we convert all measurements to kg for weight and cm for length
  def convert_unit_measurement
    unless VALID_HEIGHT_UNITS.include?(unit) || VALID_WEIGHT_UNITS.include?(unit)
      errors.add(:unit, "is invalid")
      throw(:abort)
    end
    if is_weight? && unit != 'kg'
      unit_obj = Unit.new("#{measurement} #{unit}")
      if unit_obj.compatible?(Unit.new('kg'))
        self.measurement = unit_obj.convert_to('kg').scalar.to_f
        self.unit = 'kg'
      else
        errors.add(:unit, "cannot be converted to kg")
        throw(:abort)
      end
    elsif is_height? && unit != 'cm'
      unit_obj = Unit.new("#{measurement} #{unit}")
      if unit_obj.compatible?(Unit.new('cm'))
        self.measurement = unit_obj.convert_to('cm').scalar.to_f
        self.unit = 'cm'
      else
        errors.add(:unit, "cannot be converted to cm")
        throw(:abort)
      end
    end
  end

  def unit_is_valid_for_vital_type
    valid_units = case
                  when is_weight? then VALID_WEIGHT_UNITS
                  when is_height? then VALID_HEIGHT_UNITS
                  end
    unless valid_units.include?(unit)
      errors.add(:unit, "#{unit} is not a valid unit for #{vital_type}")
    end
  end

  def set_patient_from_medical_record_number
    puts  patient.blank?, medical_record_number.present?, hospital_id.present?
    if patient_id.blank? && medical_record_number.present? && hospital_id.present?
      patient = Patient.find_by(medical_record_number: medical_record_number, hospital_id: hospital_id)
      if patient
        self.patient = patient
      else
        errors.add(:medical_record_number, "is invalid. Patient not found")
      end
    end
  end

  def require_patient_or_mrn
    if patient.blank? && medical_record_number.blank?
      errors.add(:patient, "must be present if medical record number is missing")
    end
  end
end