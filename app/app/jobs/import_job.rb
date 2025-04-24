class ImportJob < ApplicationJob
  queue_as :default

  def perform(import_id)
    @import = Import.find(import_id)
    return unless @import

    @import.update!(status: 'processing')

    begin
      file_data = @import.file_key
      yaml = @import.yaml_content
      hospital_id = @import.hospital.id

      case @import.import_type
      when 'basic_info'
        result = CsvMappers::YamlStrategy.new(file_data, yaml, hospital_id).process
        @import.update!(
          status: 'completed',
          row_count: result[:number_of_patients_saved], error_count: result[:errors].size
        )
        if result[:errors].size > 0
          puts result[:errors].inspect
        end
      else
        raise "Unsupported import type: #{@import.import_type}"
      end

      @import.update!(status: 'completed')

    rescue StandardError => e
      @import.update!(status: 'failed')
      Rails.logger.error("Import failed for import_id: #{import_id}, error: #{e.message}")
      raise e
    end
  end
end
