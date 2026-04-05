class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.references :pool, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.string :name, null: false
      # 1-based order for snake draft (e.g., 1 picks first in round 1)
      t.integer :draft_order, null: false
      t.timestamps
    end
    add_index :teams, %i[pool_id draft_order], unique: true
  end
end
