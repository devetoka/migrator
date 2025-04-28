class ImportJob < ApplicationJob
  queue_as :default

  def perform(import_id)
    start_time = Time.current
    @import = Import.find(import_id)
    return unless @import

    @import.update!(status: 'processing')

    begin
      file_key = @import.file_key
      yaml_file = @import.yaml_content
      hospital_id = @import.hospital.id

      case @import.import_type
      when 'basic_info'
        result = Importers::BasicInfoImporter.new(yaml_file, :basic_info).import(file_key, hospital_id)
      when 'vital'
        result = Importers::VitalsImporter.new(yaml_file, :vitals).import(file_key, hospital_id)
      else
        raise "Unsupported import type: #{@import.import_type}"
      end
      end_time = Time.current
      @import.update!(
        status: 'completed',
        row_count: result[:rows_count] || 0,
        error_count: result[:errors].size,
        error_logs: JSON.parse(result[:errors].to_json),
        time_taken: end_time - start_time
      )
      if result[:errors].size > 0
        puts result[:errors].inspect
      end
    rescue StandardError => e
      @import.update!(status: 'failed', error_count: 1,  error_logs: [e.message])
      Rails.logger.error("Import failed for import_id: #{import_id}, error: #{e.message}")
      raise e
    end
  end
end
