class CreateImports < ActiveRecord::Migration[7.1]
  def change
    create_table :imports do |t|
      t.references :hospital, null: false, foreign_key: true
      t.string :name, null: false
      t.text :yaml_content, null: false
      t.string :file_key, null: true
      t.string :status, default: "pending", null: false
      t.integer :row_count, default: 0
      t.integer :error_count, default: 0
      t.timestamps
    end

    add_index :imports, [:name, :hospital_id], unique: true
  end
end
