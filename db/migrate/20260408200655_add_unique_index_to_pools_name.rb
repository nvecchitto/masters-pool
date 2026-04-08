class AddUniqueIndexToPoolsName < ActiveRecord::Migration[8.0]
  def change
    add_index :pools, :name, unique: true
  end
end
