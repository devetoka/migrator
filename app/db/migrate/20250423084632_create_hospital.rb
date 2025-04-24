class CreateHospital < ActiveRecord::Migration[7.1]
  def change
    create_table :hospitals do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.timestamps
    end

    add_index :hospitals, :code, unique: true

  end
end
