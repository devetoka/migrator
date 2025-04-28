# frozen_string_literal: true
module CsvMappers
  class YamlMapper < Mapper
    def parse(file)
      begin
        YAML.safe_load(file)
      rescue StandardError => e
        raise InvalidYamlException,  "Invalid YAML file: #{e.message}"
      end
    end

    def map_row(row)
      mappings = {}
      get_mapping_section_type.each do |key, value|
        mappings[key.to_s] = value.transform_values { |client_column_name| row.fetch(client_column_name, nil) }
      end
      mappings
    end
  end
end
