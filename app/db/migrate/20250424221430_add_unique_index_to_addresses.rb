class AddUniqueIndexToAddresses < ActiveRecord::Migration[7.1]
  def change
    remove_index :addresses, :patient_id if index_exists?(:addresses, :patient_id)
    add_index :addresses, :patient_id, unique: true
  end
end
