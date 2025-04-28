# frozen_string_literal: true
class Hospital < ApplicationRecord
  has_many :imports
  has_many :patients
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
