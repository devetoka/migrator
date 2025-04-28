# frozen_string_literal: true
require "csv"

module Importers
  class BaseImporter
    include Helpers::ImportLogger
    include Helpers::ImportSummary

    BATCH_SIZE = 100

    def initialize(mapping_config, type, format)
      @mapping_config = mapping_config
      @format = format
      @type = type
      initialize_summary
    end

    def import(file, hospital_id)
      @hospital_id = hospital_id
      file_data = AwsService.new.download_file(file)
      parser = get_parser
      row_index = 0
      batch = []
      CSV.new(file_data, headers: true, col_sep: parser.get_separator).each do |row|
        row_index += 1

        begin
          mapped = parser.map_row(row)
          batch << [mapped, row_index]
          if row_index % BATCH_SIZE == 0
            process_batch(batch)
            batch = []
          end
        rescue => e
          log_errors(e.message, row_index, e.backtrace)
        end
      end

      begin
        process_batch(batch)
      rescue => e
        log_errors(e.message, row_index, e.backtrace)
      end

      @status ="success"
      {
        status: @status,
        rows_count: @rows_saved + @rows_skipped,
        error_count: @rows_failed,
        errors: @errors,
      }
    end

    protected
    def get_parser
      case @format.to_sym
      when :yaml then CsvMappers::YamlMapper.new(@mapping_config, @type)
      else
        CsvMappers::YamlMapper.new(@mapping_config, @type)
      end
    end

    def process_batch(batch)
      raise NotImplementedError, 'Subclasses must implement #map_row'
    end
  end
end
