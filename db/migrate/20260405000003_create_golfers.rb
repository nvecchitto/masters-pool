class CreateGolfers < ActiveRecord::Migration[8.0]
  def change
    create_table :golfers do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sportsdata_id, null: false
      # Score relative to par (e.g., -5 means 5 under)
      t.integer :current_score, null: false, default: 0
      # "F", "1", "9", etc.
      t.string :thru, default: "-"
      # "active", "cut", "wd", "dq"
      t.string :status, null: false, default: "active"
      t.integer :rounds_played, null: false, default: 0
      t.integer :position
      t.timestamps
    end
    add_index :golfers, %i[tournament_id sportsdata_id], unique: true
  end
end
