# frozen_string_literal: true

class PatientsController < ApplicationController
  before_action :set_patient, only: [:show]
  def show

  end

  private

  def set_patient
    @patient = Patient.includes(:hospital, :address, :vitals).find(params[:id])
  end
end
