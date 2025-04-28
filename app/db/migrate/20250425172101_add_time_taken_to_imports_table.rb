class AddTimeTakenToImportsTable < ActiveRecord::Migration[7.1]
  def change
    add_column :imports, :time_taken, :float, default: 0
  end
end
