# frozen_string_literal: true
class Patient < ActiveRecord::Base
  belongs_to :hospital
  has_one :address

  validates :medical_record_number, presence: true
  validates :first_name, :last_name, presence: true
  validates :gender, inclusion: { in: %w[M F], allow_nil: true }
  validates :medical_record_number, uniqueness: { scope: :hospital_id, message: "is already taken for this hospital" }
  validates :date_of_birth, format: { with: /\A\d{6}\z/, allow_nil: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_nil: true }

end
