# frozen_string_literal: true
module CsvMappers
  class Mapper
    def initialize(config, type = :basic_info)
      @mapping = parse(config)
      @type = type
    end
    def parse(file)
      raise NotImplementedError, 'Subclasses must implement #parse'
    end

    def get_mapping_section_type
      case @type
      when :basic_info
        {'patient' => @mapping['mappings']['patient'], 'address' => @mapping['mappings']['address']}
      when :vitals
        {'vitals' => @mapping['mappings']['vitals']}
      else
        raise InvalidYamlException, "Unsupported mapping type: #{@type}"
      end
    end

    def get_separator
      @mapping['delimiter']
    end

    def map_row(row)
      raise NotImplementedError, 'Subclasses must implement #map_row'
    end
  end
end

