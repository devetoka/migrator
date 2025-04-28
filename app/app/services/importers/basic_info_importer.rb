# frozen_string_literal: true
module Importers
  class BasicInfoImporter < BaseImporter
    def initialize(file, type, format: :yaml)
      super(file, type, format)
      @patients = []
      @identifiers = {}
    end

    def import(mapping_config, hospital_id)
      result = super(mapping_config, hospital_id)
      @identifiers.each do |key, value|
        if value.size > 1
          log_errors("Duplicate medical record number '#{key}' found in rows #{value.map { |v| v + 1 } .join('|')}", value.first)
        end
      end
      result
    end

    private

    # Processes batch: Removes duplicates, validates and stores to DB
    def process_batch(batch)
      if batch.any?
        identifiers = get_filtered_identifiers(batch)

        @existing_patients_identifiers = Patient.where(
          medical_record_number: identifiers,
          hospital_id: @hospital_id
        ).pluck(:medical_record_number)

        validate(batch, identifiers)

        save_to_database

        @existing_patients_identifiers.clear
      end
    end

    # Identifies and removes duplicates found in the csv
    # They will be recorded as error and skipped
    def get_filtered_identifiers(batch)
      filtered_identifiers = []
      batch.each do |item|
        mapped , row_index = item
        identifier = mapped['patient']['medical_record_number']
        if @identifiers.key?(identifier)
          @identifiers[identifier] << row_index
          filtered_identifiers.reject! { |entry| entry == identifier }
          next
        else
          @identifiers[identifier] = [row_index]
          filtered_identifiers << identifier
        end
      end
      filtered_identifiers
    end

    def validate(batch, filtered_identifiers)
      batch.each do |mapped, row_index|
        begin
          if !filtered_identifiers.include?(mapped['patient']['medical_record_number'])
            log_errors('Duplicate medical record number', row_index)
          else
            validate_and_create_patient_with_address(mapped, row_index) if mapped['patient'].present?
          end

        rescue => e
          log_errors(e.message, row_index, e.backtrace)
        end
      end
    end

    def validate_and_create_patient_with_address(mapped, row_index)
      errors = []
      patient = Patient.new(mapped['patient'])
      patient[:hospital_id] = @hospital_id

      if @existing_patients_identifiers.include?(patient.medical_record_number)
        patient.skip_mrn_validation = true
        increment_skipped_rows
        return
      end

      if mapped['address'].present?
        patient.address = Address.new(mapped['address'])

        unless patient.address.valid?
          errors << patient.address.errors.full_messages
        end
      end
      if patient.valid? && errors.empty?
        @patients << { patient: patient, row_index: row_index }
      else
        errors << patient.errors.full_messages if patient.errors.any?
        raise StandardError, "Validation failed: #{errors.flatten.join(', ')}"
      end
    end

    def save_to_database
      return if @patients.empty?

      patients = []
      addresses = []
      patient_with_row_number = {}

      @patients.each do |patient|
        patient_object = patient[:patient]
        row = patient[:row_index]
        patients << patient_object

        # here, we try to store the row number so we can refer to it if error occurs
        # the email is already set, otherwise, the validation method would have raised an error
        patient_with_row_number[patient_object.email] = row

        if patient_object.address.present?
          address = patient_object.address.attributes.symbolize_keys
          address[:email] = patient_object.email if patient_object.email.present?

          addresses << address
        end
      end
      @patients.clear

      saved = ActiveRecord::Base.transaction do
        imported_patients = save_patients_to_db(patient_with_row_number, patients)

        save_addresses_to_db(addresses, imported_patients, patient_with_row_number)
        true
      end

      unless saved
        raise StandardError, "Unable to save #{@patients.size} patients to db"
      end
    end

    def save_patients_to_db(patient_with_row_number, patients)
      imported_patients = Patient.import(
        patients,
        on_duplicate_key_ignore: true,
        returning: [:id, :email, :first_name]
      )

      handle_failed_import(imported_patients, patient_with_row_number, :patient)
      @rows_saved += imported_patients.results.size
      imported_patients
    end

    def save_addresses_to_db(addresses, imported_patients, patient_with_row_number)
      valid_addresses, successful_inserts = get_valid_addresses(addresses, imported_patients)

      if valid_addresses.any?

        imported_addresses = Address.import(
          valid_addresses,
          on_duplicate_key_update: {
            conflict_target: [:patient_id],
            columns: Address.column_names - %w[id created_at, updated_at]
          },
          )
        handle_failed_import(imported_addresses, patient_with_row_number, :address, successful_inserts)
      end
    end

    # Return addresses of patients that were successfully saved
    def get_valid_addresses(addresses, imported_patients)
      successful_inserts = imported_patients.results.map { |result| [result[0], result[1]] }
      valid_addresses = []

      successful_inserts.each do |id, email|
        matching_address = addresses.find { |a| a[:email] == email }

        if matching_address
          matching_address[:patient_id] = id
          matching_address.delete(:email)
          valid_addresses << matching_address
        end
      end

      [valid_addresses, successful_inserts]
    end


    def handle_failed_import(imported, rows_holder, type, patients_data = nil)
      if imported.failed_instances.any?
        imported.failed_instances.each do | item |
          row_number = nil
          if type.to_sym == :patient
            row_number = rows_holder.find { |key, _| key == item.email }
          elsif type.to_sym == :address && patients_data.present?
            patient = patients_data.find { |p| p[:id] == item[:patient_id] }
            row_number = rows_holder[patient.email] if patient
          end
          log_errors(item.errors.full_messages, row_number || 'N/A')
        end
      end
    end
  end
end
