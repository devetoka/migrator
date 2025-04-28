# frozen_string_literal: true
class HospitalsController < ApplicationController
  before_action :set_hospital, only: [:show]
  def index
    @hospitals = Hospital.order(created_at: :desc)
  end
  def new
    @hospital = Hospital.new
  end

  def show
    @patients = @hospital.patients.includes(:address).order(:first_name)
  end

  def create
    @hospital = Hospital.new(hospital_params)
    if @hospital.save
      redirect_to new_hospital_import_path(hospital_id: @hospital.id), notice: "Hospital created successfully. You may now upload migration file"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_hospital
    @hospital = Hospital.find(params[:id])
  end


  def hospital_params
    params.require(:hospital).permit(:name, :code)
  end
end