class AddTypeToImports < ActiveRecord::Migration[7.1]
  def change
    add_column :imports, :import_type, :string, null: false
  end
end
