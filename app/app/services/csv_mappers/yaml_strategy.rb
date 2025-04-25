# frozen_string_literal: true
module CsvMappers
  class YamlStrategy < AbstractStrategy
    def initialize(file_data, yaml_file, hospital_id)
      super(file_data, hospital_id)
      begin
        @mapping = YAML.safe_load(yaml_file)
      rescue StandardError => e
        raise InvalidYamlException,  "Invalid YAML file: #{e.message}"
      end
    end
    def map_row(row)
      mappings = {}
      @mapping["mappings"].each do |key, value|
        mappings[key.to_s] = value.transform_values { |client_column_name| row.fetch(client_column_name, nil) }
      end
      mappings
    end

    def get_separator
      @mapping['delimiter']
    end
  end
end
