# frozen_string_literal: true
class Patient < ActiveRecord::Base

  attr_accessor :skip_mrn_validation
  belongs_to :hospital
  has_one :address

  before_validation :transform_values

  validates :medical_record_number, presence: true, format: { 
    with: /\d+/, 
    message: "contains invalid value" 
  }
  validates :medical_record_number,
          uniqueness: { scope: :hospital_id, message: "is already taken for this hospital" },
          unless: :skip_mrn_validation
  validates :first_name, :last_name, presence: true, format: { 
    with: /\A[a-zA-Z\-]+\z/, 
    message: "must only contain letters or hyphens" 
  }
  validates :gender, inclusion: { in: %w[M F], allow_nil: false, message: "Invalid gender/sex" }
  validates :date_of_birth, format: { with: /\A\d{4}-\d{2}-\d{2}\z/, allow_nil: false, message: "not a valid date" }
  validates :phone_number, presence: { message: "phone number is required"}
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_nil: false }


  private

  def transform_values
    self.gender = case self.gender&.downcase
      when 'male' then 'M'
      when 'female' then 'F'
      else self.gender
    end

    begin
      self.date_of_birth = Date.parse(self.date_of_birth.to_s).strftime('%Y-%m-%d') if self.date_of_birth.present?
    rescue ArgumentError
      self.date_of_birth = nil
    end
  end
  


end
