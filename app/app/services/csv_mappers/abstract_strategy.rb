# frozen_string_literal: true
require "csv"

module CsvMappers
  class AbstractStrategy
    BATCH_SIZE = 100

    def initialize(path, hospital_id)
      @file_data = AwsService.new.download_file(path)
      @hospital_id = hospital_id
      @patients = []
      @number_of_patients_saved = 0
      @number_of_patients_skipped = 0
      @number_of_addresses_saved = 0
      @errors = []
      @batch = []
      @mrns = {}
    end

    def process
      row_index = 0
      CSV.new(@file_data, headers: true, col_sep: get_separator).each do |row|
        row_index += 1

        begin
          mapped = map_row(row)
          @batch << [mapped, row_index]

          process_batch if row_index % BATCH_SIZE == 0
        rescue => e
          log_errors(e.message, row_index, e.backtrace)
        end
      end

      begin
        process_batch
      rescue => e
        log_errors(e.message, row_index, e.backtrace)
        return {
          status: 'failed',
          number_of_patients_saved: @number_of_patients_saved + @number_of_patients_skipped,
          number_of_addresses_saved: @number_of_addresses_saved,
          errors: @errors,
        }
      end

      @mrns.each do |key, value|
        if value.size > 1
          log_errors("Duplicate medical record number '#{key}' found in rows #{value.join(', ')}", value.first)
        end
      end      

      {
        status: 'success',
        number_of_patients_saved: @number_of_patients_saved + @number_of_patients_skipped,
        number_of_addresses_saved: @number_of_addresses_saved,
        errors: @errors,
      }
    end

    protected
    def map_row(row)
      raise NotImplementedError, "Implement this method"
    end

    def get_separator()
      raise NotImplementedError, "Implement this method"
    end

    private

    # Identifies and removes duplicates from the csv
    # They will be recorded as error and skipped
    def get_filtered_mrn
      filtered_mrn = []
        @batch.each do |item| 
          mapped , row_index = item
          mrn = mapped['patient']['medical_record_number'] 
          if @mrns.key?(mrn)
            @mrns[mrn] << row_index
            filtered_mrn.reject! { |entry| entry == mrn }
            next
          else
            @mrns[mrn] = [row_index]
            filtered_mrn << mrn
          end
        end
      filtered_mrn
    end

    def validate(filtered_mrn)
      @batch.each do |mapped, row_index|
        begin
          if !filtered_mrn.include?(mapped['patient']['medical_record_number'])
            log_errors('Duplicate medical record number', row_index)
          else
            validate_and_create_patient_with_address(mapped, row_index) if mapped['patient'].present?
          end

        rescue => e 
          log_errors(e.message, row_index, e.backtrace)
        end
      end
    end



    # Processes batch: Removes duplicates, validates and stores to DB
    def process_batch
      if @batch.any?
        mrns = get_filtered_mrn
        
        @existing_patients_mrn = Patient.where(medical_record_number: mrns, hospital_id: @hospital_id).pluck(:medical_record_number)
        
        validate(mrns)
        
        save_to_database
    
        @batch.clear
        @existing_patients_mrn.clear
      end
    end
    

    # creates model and runs model validations
    def validate_and_create_patient_with_address(mapped, row_index)
      errors = []
      patient = Patient.new(mapped['patient'])
      patient[:hospital_id] = @hospital_id

      if @existing_patients_mrn.include?(patient.medical_record_number)
        patient.skip_mrn_validation = true
        @number_of_patients_skipped += 1
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

        # here, we try to store the row so we can refer to it if error occurs
        # the email is already set, otherwise, the validation method would have raised an error
        patient_with_row_number[patient_object.email] = row

        if patient_object.address.present?
          address = patient_object.address.attributes.symbolize_keys
          address[:email] = patient_object.email if patient_object.email.present?


          addresses << address
        end
      end
      @patients.clear

      imported_patients = save_patients_to_db(patient_with_row_number, patients)

      save_addresses_to_db(addresses, imported_patients, patient_with_row_number)
    end

    def save_patients_to_db(patient_with_row_number, patients)
      imported_patients = Patient.import(
        patients,
        on_duplicate_key_ignore: true,
        returning: [:id, :email, :first_name]
      )

      handle_failed_patient_import_errors(imported_patients, patient_with_row_number)
      @number_of_patients_saved += imported_patients.results.size
      imported_patients
    end

    def save_addresses_to_db(addresses, imported_patients, patient_with_row_number)
      valid_addresses, successful_inserts = get_valid_addresses(addresses, imported_patients, patient_with_row_number)

      if valid_addresses.any?

        imported_addresses = Address.import(
          valid_addresses,
          on_duplicate_key_update: {
            conflict_target: [:patient_id],
            columns: Address.column_names - ['id', 'created_at', 'updated_at']
          },
        )
        @number_of_addresses_saved += imported_addresses.results.size
        handle_failed_address_import_errors(imported_addresses, patient_with_row_number, successful_inserts)
      end
    end

    def handle_failed_address_import_errors(imported_addresses, patient_with_row_number, imported_patients_data)
      if imported_addresses.failed_instances.any?
        imported_addresses.failed_instances.each do |a|
          patient = imported_patients_data.find { |p| p[:id] == a[:patient_id] }
          row = patient_with_row_number[patient.email] if patient
          log_errors(a.errors.full_messages, 'Could not store address record', row || 'N/A')
        end
      end
    end

    def handle_failed_patient_import_errors(imported, rows_holder)
      if imported.failed_instances.any?
        imported.failed_instances.each do |p|
          row_number = rows_holder.find { |key, value| key == p.email }
          log_errors(p.errors.full_messages, 'Could not store patient record', row_number)
        end
      end
    end

    # Return addresses of patients that were successfully saved
    def get_valid_addresses(addresses, imported_patients, row_numbers)
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

    def log_errors(message, row_index, backtrace = nil)
      context = {}
      if backtrace.present?
        file, line = backtrace.first.split(':')
        context = {file: file, line: line}
      end

      existing_error = @errors.find { |e| e[:line] == row_index }

      if existing_error 
        existing_error[:error] += ", #{message}"
      else
        @errors << { error: message, line: row_index, context: context }
      end

    end

  end
end
