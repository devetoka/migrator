# frozen_string_literal: true
class ImportsController < ApplicationController
  before_action :set_hospital, only: [:index, :new, :create]

  def index
    if @hospital.present?
      @imports = @hospital&.imports
    else
      @imports = Import.all || []
    end
  end
  def new
    @import = @hospital.imports.new
  end

  def create
    @import = @hospital.imports.new

    unless params[:import][:yaml_content].present?
      render json: { error: "Missing mapping file" }, status: :unprocessable_entity
      return
    end

    @import.yaml_content = params[:import][:yaml_content].read
    @import.import_type = params[:import][:import_type]

    if @import.save
      file_key = "uploads/imports/#{@import.name}_#{params[:import][:import_type]}.csv"
      presigned_url_data = AwsService.new.generate_presigned_url(file_key)

      render json: {
        import_id: @import.id,
        file_key: file_key,
        presigned_url: presigned_url_data[:presigned_url]
      }, status: :created
    else
      render json: { errors: @import.errors.full_messages }, status: :unprocessable_entity
    end
  end


  def sample_yaml
    file_path = Rails.root.join("app", "assets", "files", "sample-import-mapping.yaml")
    send_file file_path, filename: "sample_import_mapping.yaml", type: "application/x-yaml"
  end

  def download_yaml
    @import = Import.find(params[:id])
    send_data @import.yaml_content,
              filename: "#{@import.name.parameterize}_mapping.yml",
              type: "application/x-yaml",
              disposition: "attachment"
  end


  def uploaded
    import = Import.find(params[:id])

    if import.update(file_key: params[:file_key])
      ImportJob.perform_later(import.id)
      render json: { message: 'File path updated successfully' }, status: :ok
    else
      render json: { errors: import.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_hospital
    @hospital = Hospital.find(params[:hospital_id]) if params[:hospital_id].present?
  end
end
