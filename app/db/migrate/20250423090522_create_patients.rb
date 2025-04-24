class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.string :medical_record_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone_number
      t.date :date_of_birth
      t.string :gender
      t.references :hospital, null: false, foreign_key: true
      t.timestamps
    end


    add_index :patients, [:medical_record_number, :hospital_id], unique: true, name: "index_patients_on_mrn_and_hospital_id"
  end
end
