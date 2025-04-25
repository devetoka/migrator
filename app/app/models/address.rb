# frozen_string_literal: true
class Address < ApplicationRecord
  belongs_to :patient
  before_save :set_country

  before_validation :infer_country_and_normalize
  validates :region, inclusion: { in: :valid_regions, message: "is not a valid region" }, presence: { message: "can't be blank" }
  validates :country, inclusion: { in: ->(_) { Carmen::Country.all.map(&:name) }, allow_nil: true }
  validates :street, :city, :region, :postal_code, presence: true


  private

  def infer_country_and_normalize
    infer_country_from_region
    normalize_region
  end

  def infer_country_from_region
    return unless region.present? && country.blank?

    Carmen::Country.all.each do |country_obj|
      subregion = country_obj.subregions.named(region) || country_obj.subregions.coded(region)
      if subregion
        self.country = country_obj.name
        break
      end
    end
  end

  def normalize_country
    return unless country.present?
    country_obj = Carmen::Country.named(country) || Carmen::Country.coded(country)
    self.country = country_obj&.name if country_obj
  end

  def normalize_region
    return unless country.present? && region.present?
    country_obj = Carmen::Country.named(country)
    return unless country_obj

    subregion = country_obj.subregions.named(region) || country_obj.subregions.coded(region)
    self.region = subregion&.name if subregion
  end

  def valid_regions
    Carmen::Country.all.flat_map { |c| c.subregions.map(&:name) }.uniq
  end
end
