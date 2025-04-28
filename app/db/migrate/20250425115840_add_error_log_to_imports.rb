class AddErrorLogToImports < ActiveRecord::Migration[7.1]
  def change
    add_column :imports, :error_logs, :jsonb, default: []
  end
end
