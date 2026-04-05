class CreateTournaments < ActiveRecord::Migration[8.0]
  def change
    create_table :tournaments do |t|
      t.string :name, null: false
      t.string :sportsdata_id, null: false
      # "upcoming", "in_progress", "complete"
      t.string :status, null: false, default: "upcoming"
      t.integer :total_rounds, null: false, default: 4
      t.timestamps
    end
    add_index :tournaments, :sportsdata_id, unique: true
  end
end
