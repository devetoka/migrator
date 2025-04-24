class CreateAddress < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :street
      t.string :city
      t.string :region
      t.string :postal_code
      t.string :country
      t.timestamps
    end
  end
end
