# frozen_string_literal: true
module Importers
  class VitalsImporter < BaseImporter
    def initialize(file, type, format: :yaml)
      super(file, type, format)
      @vitals = []
    end

    protected

    def process_batch(batch)
      if batch.any?
        create_and_validate_vitals(batch)
        save_to_database
      end
    end

    private

    def create_and_validate_vitals(batch)
      batch.each do |mapped, row_index|
        begin
          mapped['vitals']['hospital_id'] = @hospital_id
          vital = Vital.new(mapped['vitals'])

          if vital.valid?
            @vitals << vital
          else
            message = "Validation failed: #{vital.errors.full_messages.flatten.join(', ')}"
            log_errors(message, row_index)
          end
        rescue => e
          log_errors(e.message, row_index, e.backtrace)
        end
      end
    end

    def save_to_database
      imported_vitals = Vital.import(
        @vitals,
        on_duplicate_key_ignore: true,
        returning: [:id]
      )
      @rows_saved += imported_vitals.results.size
    end
  end
end
