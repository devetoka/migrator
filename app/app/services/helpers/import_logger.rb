# frozen_string_literal: true
module Helpers
  module ImportLogger
    def log_errors(message, row_index, backtrace = nil)
      context = {}
      if backtrace.present?
        file, line = backtrace.first.split(':')
        context = { file: file, line: line }
      end

      @errors ||= []

      existing_error = @errors.find { |e| e[:line] == row_index }

      if existing_error
        existing_error[:error] += ", #{message}"
      else
        @errors << { error: message, line: row_index, context: context }
      end
    end
  end
end
