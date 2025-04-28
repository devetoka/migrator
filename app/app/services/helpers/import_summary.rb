# frozen_string_literal: true
module Helpers
  module ImportSummary
    attr_accessor :rows_saved, :rows_skipped, :rows_failed

    def initialize_summary
      @rows_saved = 0
      @rows_skipped = 0
      @rows_failed = 0
    end

    def increment_saved_rows
      @rows_saved += 1
    end

    def increment_skipped_rows
      @rows_skipped += 1
    end

    def increment_failed_rows
      @rows_failed += 1
    end
  end
end
