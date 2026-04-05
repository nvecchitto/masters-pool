class CreatePools < ActiveRecord::Migration[8.0]
  def change
    create_table :pools do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :name, null: false
      # Tracks which overall pick number the draft is on (1-based)
      t.integer :current_pick_number, null: false, default: 1
      # "predraft", "drafting", "complete"
      t.string :draft_status, null: false, default: "predraft"
      t.timestamps
    end
  end
end
